class Transaction < ApplicationRecord
  belongs_to :wallet

  validates :transaction_hash, presence: true, uniqueness: { scope: :wallet_id }
  validates :transaction_type, inclusion: { in: %w[send receive] }
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: %w[pending confirmed failed] }

  scope :confirmed, -> { where(status: "confirmed") }
  scope :pending, -> { where(status: "pending") }
  scope :recent, -> { order(created_at: :desc) }

  def confirmed?
    status == "confirmed"
  end

  def pending?
    status == "pending"
  end

  def failed?
    status == "failed"
  end

  def etherscan_url
    case Rails.env
    when "production"
      "https://etherscan.io/tx/#{transaction_hash}"
    else
      "https://sepolia.etherscan.io/tx/#{transaction_hash}"
    end
  end
end
