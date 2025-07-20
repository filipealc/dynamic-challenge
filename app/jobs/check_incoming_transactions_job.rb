class CheckIncomingTransactionsJob < ApplicationJob
  queue_as :blockchain

  def perform
    # Returns false if its not running
    if BlockchainState.get_processing_lock_state
      return
    end

    BlockchainState.set_processing_lock_state(true)

    begin
      # Get the latest block number from blockchain
      latest_block = EthereumService.get_latest_block_number

      # Get the last processed block from our database
      last_processed_block = BlockchainState.get_last_processed_block

      # Process blocks from last processed + 1 to latest
      (last_processed_block + 1..latest_block).each do |block_number|
        Rails.logger.info "Processing block #{block_number}"
        process_block(block_number)
      end

      # Update the last processed block in database
      BlockchainState.set_last_processed_block(latest_block)

    rescue => e
      Rails.logger.error "Error in blockchain processing: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
    ensure
      BlockchainState.set_processing_lock_state(false)
    end
  end

  private

  def process_block(block_number)
    begin
      # Get block data with transactions
      block_data = EthereumService.get_block_with_transactions(block_number)
      return unless block_data

      # Build lookup structures once per block, if we are under the same execution
      # the ||= will take care of not calling all our wallets again
      build_managed_addresses_set
      build_address_to_wallet_map

      # Get block timestamp
      block_timestamp = Time.at(block_data["timestamp"].to_i(16))

      transactions = block_data["transactions"] || []

      # Filter relevant transactions first
      relevant_transactions = transactions.select do |tx|
        incoming_transaction?(tx)
      end

      # Process only relevant transactions
      relevant_transactions.each do |tx|
        process_transaction(tx, block_timestamp, block_number)
      end

    rescue => e
      Rails.logger.error "Error processing block #{block_number}: #{e.message}"
    end
  end

  # Build Set once per block
  def build_managed_addresses_set
    @managed_addresses_set ||= Set.new(Wallet.pluck(:address))
  end

  # Build address-to-wallet mapping once per block
  def build_address_to_wallet_map
    @address_to_wallet_map ||= Wallet.all.index_by(&:address)
  end

  def process_transaction(tx, block_timestamp, block_number)
    # Use the pre-built map
    wallet = @address_to_wallet_map[tx["to"]]
    return unless wallet

    # Check if we already have this transaction
    return if Transaction.exists?(transaction_hash: tx["hash"], transaction_type: "receive", wallet_id: wallet.id)

    # Create transaction record with blockchain timestamp
    transaction = wallet.transactions.create!(
      transaction_type: "receive",
      amount: tx["value"].to_i(16) / 10**18.0, # Convert from wei to ETH (hex string to integer)
      from_address: tx["from"],
      to_address: tx["to"],
      transaction_hash: tx["hash"],
      status: "confirmed",
      block_number: block_number
    )

    # Override the created_at timestamp with the blockchain timestamp
    transaction.update_column(:created_at, block_timestamp)
  end

  def incoming_transaction?(tx)
    @managed_addresses_set.include?(tx["to"])
  end
end
