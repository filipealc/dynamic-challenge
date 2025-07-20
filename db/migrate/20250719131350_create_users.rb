class CreateUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :users do |t|
      t.string :auth0_id
      t.string :email
      t.string :name
      t.string :picture

      t.timestamps
    end
    add_index :users, :auth0_id, unique: true
    add_index :users, :email, unique: true
  end
end
