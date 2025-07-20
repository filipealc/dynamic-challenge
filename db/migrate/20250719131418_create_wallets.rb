class CreateWallets < ActiveRecord::Migration[7.2]
  def change
    create_table :wallets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :address, null: false
      t.text :private_key, null: false

      t.timestamps
    end

    add_index :wallets, :address, unique: true
  end
end
