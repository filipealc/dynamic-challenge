class CreateTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :transactions do |t|
      t.references :wallet, null: false, foreign_key: true
      t.string :transaction_hash, null: false
      t.string :transaction_type, null: false
      t.string :to_address
      t.string :from_address
      t.decimal :amount, precision: 36, scale: 18, null: false  # Supports up to 18 decimal places for Wei precision
      t.string :status, default: 'pending', null: false
      t.integer :block_number
      t.integer :gas_used

      t.timestamps
    end

    # Composite unique index: transaction_hash + wallet_id
    # This allows the same transaction to be recorded for both sender and receiver wallets
    add_index :transactions, [ :transaction_hash, :wallet_id ], unique: true

    # Regular index on transaction_hash for querying
    add_index :transactions, :transaction_hash

    add_index :transactions, :status
    add_index :transactions, [ :wallet_id, :created_at ]
  end
end
