class Api::V1::WalletsController < Api::V1::BaseController
  before_action :set_wallet, only: [ :show, :sign_message, :send_transaction ]

  def index
    wallets = current_user.wallets.includes(:transactions).order(created_at: :desc)

    render_success({
      wallets: wallets.map do |wallet|
        {
          id: wallet.id,
          name: wallet.name,
          address: wallet.address,
          balance: wallet.balance,
          transaction_count: wallet.transactions.count,
          created_at: wallet.created_at
        }
      end
    })
  end

  def create
    begin
      # Use the user's add_wallet method
      wallet = current_user.add_wallet(wallet_params[:name])

      render_success({
        wallet: {
          id: wallet.id,
          name: wallet.name,
          address: wallet.address,
          created_at: wallet.created_at
        }
      }, "Wallet created successfully!")

    rescue => e
      Rails.logger.error "API: Failed to create wallet: #{e.message}"
      render_error("Failed to create wallet: #{e.message}")
    end
  end

  def show
    render_success({
      wallet: {
        id: @wallet.id,
        name: @wallet.name,
        address: @wallet.address,
        balance: @wallet.balance,
        transactions: @wallet.transactions.recent.limit(10).map do |tx|
          {
            id: tx.id,
            transaction_hash: tx.transaction_hash,
            transaction_type: tx.transaction_type,
            to_address: tx.to_address,
            from_address: tx.from_address,
            amount: tx.amount,
            status: tx.status,
            block_number: tx.block_number,
            gas_used: tx.gas_used,
            created_at: tx.created_at,
            etherscan_url: tx.etherscan_url
          }
        end,
        created_at: @wallet.created_at
      }
    })
  end

  def sign_message
    message = params[:message]

    if message.blank?
      return render_error("Message is required")
    end

    begin
      signature = @wallet.sign_message(message)
      render_success({
        message: message,
        signature: signature,
        wallet_address: @wallet.address
      }, "Message signed successfully!")
    rescue => e
      Rails.logger.error "Failed to sign message for wallet #{@wallet.id}: #{e.message}"
      render_error("Failed to sign message")
    end
  end

  def send_transaction
    to_address = params[:to]
    amount = params[:amount].to_f

    # Validation
    if to_address.blank?
      Rails.logger.warn "API: Missing recipient address"
      return render_error("Recipient address is required")
    end

    if amount <= 0
      Rails.logger.warn "API: Invalid amount: #{amount}"
      return render_error("Amount must be greater than 0")
    end

    # Validate Ethereum address format
    unless to_address.match?(/^0x[a-fA-F0-9]{40}$/)
      Rails.logger.warn "API: Invalid address format: #{to_address}"
      return render_error("Invalid Ethereum address format")
    end

    # Check if user has sufficient balance
    current_balance = @wallet.balance

    if current_balance < amount
      Rails.logger.warn "API: Insufficient balance. Required: #{amount}, Available: #{current_balance}"
      return render_error("Insufficient balance. Available: #{current_balance} ETH")
    end

    begin
      tx_hash = @wallet.send_transaction(to_address, amount)

      render_success({
        transaction_hash: tx_hash,
        to_address: to_address,
        amount: amount,
        from_address: @wallet.address,
        status: "pending"
      }, "Transaction sent successfully!")

    rescue => e
      Rails.logger.error "API: Failed to send transaction from wallet #{@wallet.id}: #{e.message}"
      Rails.logger.error "API: Full error: #{e.backtrace.join("\n")}"

      # Parse specific errors
      error_message = case e.message
      when /insufficient funds/i
        "Insufficient funds for transaction and gas fees"
      when /gas/i
        "Transaction failed due to gas estimation error"
      when /nonce/i
        "Transaction failed due to nonce error. Please try again."
      else
        "Failed to send transaction. Please try again."
      end

      render_error(error_message)
    end
  end

  private

  def set_wallet
    @wallet = current_user.wallets.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Wallet not found", :not_found)
  end

  def wallet_params
    params.require(:wallet).permit(:name)
  end
end
