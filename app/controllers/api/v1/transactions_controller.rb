class Api::V1::TransactionsController < Api::V1::BaseController
  before_action :set_transaction, only: [ :show ]

  # Sample endpoint as to how we could list transactions with pagination
  # this is not being currently used on the demo
  def index
    transactions = current_user.transactions
                               .joins(:wallet)
                               .includes(:wallet)
                               .recent
                               .page(params[:page])
                               .per(20)

    render_success({
      transactions: transactions.map do |tx|
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
          wallet: {
            id: tx.wallet.id,
            name: tx.wallet.name,
            address: tx.wallet.address
          },
          created_at: tx.created_at,
          etherscan_url: tx.etherscan_url
        }
      end,
      pagination: {
        current_page: transactions.current_page,
        total_pages: transactions.total_pages,
        total_count: transactions.total_count,
        per_page: 20
      }
    })
  end

  def show
    render_success({
      transaction: {
        id: @transaction.id,
        transaction_hash: @transaction.transaction_hash,
        transaction_type: @transaction.transaction_type,
        to_address: @transaction.to_address,
        from_address: @transaction.from_address,
        amount: @transaction.amount,
        status: @transaction.status,
        block_number: @transaction.block_number,
        gas_used: @transaction.gas_used,
        wallet: {
          id: @transaction.wallet.id,
          name: @transaction.wallet.name,
          address: @transaction.wallet.address
        },
        created_at: @transaction.created_at,
        updated_at: @transaction.updated_at,
        etherscan_url: @transaction.etherscan_url
      }
    })
  end

  private

  def set_transaction
    @transaction = current_user.transactions
                               .joins(:wallet)
                               .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_error("Transaction not found", :not_found)
  end
end
