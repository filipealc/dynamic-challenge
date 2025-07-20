# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_07_19_172200) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "blockchain_states", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_blockchain_states_on_key", unique: true
  end

  create_table "transactions", force: :cascade do |t|
    t.bigint "wallet_id", null: false
    t.string "transaction_hash", null: false
    t.string "transaction_type", null: false
    t.string "to_address"
    t.string "from_address"
    t.decimal "amount", precision: 36, scale: 18, null: false
    t.string "status", default: "pending", null: false
    t.integer "block_number"
    t.integer "gas_used"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_transactions_on_status"
    t.index ["transaction_hash", "wallet_id"], name: "index_transactions_on_transaction_hash_and_wallet_id", unique: true
    t.index ["transaction_hash"], name: "index_transactions_on_transaction_hash"
    t.index ["wallet_id", "created_at"], name: "index_transactions_on_wallet_id_and_created_at"
    t.index ["wallet_id"], name: "index_transactions_on_wallet_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "auth0_id"
    t.string "email"
    t.string "name"
    t.string "picture"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["auth0_id"], name: "index_users_on_auth0_id", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "wallets", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "address", null: false
    t.text "private_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_wallets_on_address", unique: true
    t.index ["user_id"], name: "index_wallets_on_user_id"
  end

  add_foreign_key "transactions", "wallets"
  add_foreign_key "wallets", "users"
end
