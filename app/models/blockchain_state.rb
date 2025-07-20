class BlockchainState < ApplicationRecord
  validates :key, presence: true, uniqueness: true

  def self.get_last_processed_block
    state = find_by(key: "last_processed_block")
    state ? state.value.to_i : 0
  end

  def self.set_last_processed_block(block_number)
    state = find_or_initialize_by(key: "last_processed_block")
    state.value = block_number.to_s
    state.save!
  end

  def self.initialize_with_current_block
    # Get current block number from blockchain
    current_block = EthereumService.get_latest_block_number
    existing_block = get_last_processed_block

    if existing_block == 0
      # First time initialization - set to current block
      set_last_processed_block(current_block)
    end
  end

  def self.get_processing_lock_state
    state = find_or_initialize_by(key: "processing_lock")
    unless state.persisted?
      state.value = false
      state.save!
    end
    ActiveModel::Type::Boolean.new.cast(state.value)
  end

  def self.set_processing_lock_state(value)
    state = find_or_initialize_by(key: "processing_lock")
    state.update_column(:value, value)
  end
end
