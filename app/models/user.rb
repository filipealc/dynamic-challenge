class User < ApplicationRecord
  has_many :wallets, dependent: :destroy
  has_many :transactions, through: :wallets

  validates :auth0_id, presence: true, uniqueness: true
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  after_create :create_default_wallet

  def total_balance
    wallets.sum(&:balance)
  end

  def primary_wallet
    wallets.first
  end

  def add_wallet(name)
    # Use the wallet creation service with force_create=true
    wallet = WalletCreationService.create_wallet_for_user(self, name, force_create: true)
    wallet
  rescue => e
    Rails.logger.error "User #{id}: Failed to create wallet: #{e.message}"
    raise "Failed to create wallet: #{e.message}"
  end

  private

  def create_default_wallet
    # Use the service synchronously instead of background job
    WalletCreationService.create_wallet_for_user(self)
  end
end
