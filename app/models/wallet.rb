class Wallet < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :destroy

  validates :address, presence: true, uniqueness: true
  validates :name, presence: true
  validates :private_key, presence: true

  before_create :generate_wallet_keypair

  scope :oldest, -> { order(created_at: :asc) }

  def balance
    # Get balance from blockchain
    EthereumService.get_balance(address)
  rescue => e
    Rails.logger.error "Failed to get balance for wallet #{id}: #{e.message}"
    0.0
  end

  def sign_message(message)
    EthereumService.sign_message(message, private_key)
  end

  def send_transaction(to_address, amount)
    tx_hash = EthereumService.send_transaction(
      address,
      to_address,
      amount,
      private_key
    )

    # Record the transaction
    transactions.create!(
      transaction_hash: tx_hash,
      transaction_type: "send",
      to_address: to_address,
      from_address: address,
      amount: amount,
      status: "pending"
    )

    # Start monitoring the transaction
    TransactionMonitorJob.perform_later(tx_hash)

    tx_hash
  end

  private

  def generate_wallet_keypair
    return if address.present? && private_key.present?

    keypair = EthereumService.create_wallet
    self.address = keypair[:address].to_s.downcase
    self.private_key = keypair[:private_key]
    self.name ||= "Wallet #{user.wallets.count + 1}"
  end
end
