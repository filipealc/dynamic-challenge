class CreateBlockchainState < ActiveRecord::Migration[7.2]
  def change
    create_table :blockchain_states do |t|
      t.string :key, null: false
      t.text :value
      t.timestamps
    end

    add_index :blockchain_states, :key, unique: true

    # Insert initial blockchain state
    # We'll start from a recent block to avoid processing entire history
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO blockchain_states (key, value, created_at, updated_at)
          VALUES ('last_processed_block', '0', NOW(), NOW())
        SQL
      end
    end
  end
end
