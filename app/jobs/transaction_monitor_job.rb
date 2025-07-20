class TransactionMonitorJob < ApplicationJob
  queue_as :default

  MAX_RETRIES = 120
  RETRY_INTERVAL = 5.seconds

  def perform(transaction_hash, retry_count = 0)
    transaction = Transaction.find_by(transaction_hash: transaction_hash)

    unless transaction
      Rails.logger.error "Transaction with hash #{transaction_hash} not found"
      return
    end

    # Don't monitor if already confirmed or failed
    return if transaction.confirmed? || transaction.failed?

    # Get transaction receipt from blockchain
    receipt = EthereumService.get_transaction_receipt(transaction_hash)

    if receipt
      block_number = receipt["blockNumber"].to_i(16)
      # Get block timestamp for accurate blockchain time
      block_timestamp = get_block_timestamp(block_number)
      # Transaction is mined
      if receipt["status"] == "0x1"
        transaction.update!(
          status: "confirmed",
          block_number: block_number,
          gas_used: receipt["gasUsed"].to_i(16)
        )
      else
        transaction.update!(
          status: "failed",
          block_number: block_number
        )
      end
      # Update timestamp to blockchain time if available
      transaction.update_column(:created_at, block_timestamp) if block_timestamp
    else
      # Transaction still pending
      if retry_count < MAX_RETRIES
        # Retry later
        TransactionMonitorJob.set(wait: RETRY_INTERVAL)
                            .perform_later(transaction_hash, retry_count + 1)
      else
        # Max retries reached, mark as failed
        transaction.update!(status: "failed")
        Rails.logger.error "Transaction #{transaction_hash} failed after #{MAX_RETRIES} retries"
      end
    end

  rescue => e
    Rails.logger.error "Error monitoring transaction #{transaction_hash}: #{e.message}"

    # Retry on error unless max retries reached
    if retry_count < MAX_RETRIES
      TransactionMonitorJob.set(wait: RETRY_INTERVAL)
                          .perform_later(transaction_hash, retry_count + 1)
    else
      transaction&.update!(status: "failed") if transaction
    end
  end

  private

  def get_block_timestamp(block_number)
    block_data = EthereumService.get_block_with_transactions(block_number)
    block_data ? Time.at(block_data["timestamp"].to_i(16)) : nil
  end
end
