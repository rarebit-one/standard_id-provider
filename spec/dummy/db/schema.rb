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

ActiveRecord::Schema[8.0].define(version: 2025_08_31_154635) do
  create_table "accounts", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_accounts_on_email", unique: true
  end

  create_table "standard_id_credentials", force: :cascade do |t|
    t.integer "identifier_id", null: false
    t.string "credentialable_type", null: false
    t.integer "credentialable_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credentialable_type", "credentialable_id"], name: "index_standard_id_credentials_on_credentialable"
    t.index ["identifier_id"], name: "index_standard_id_credentials_on_identifier_id"
  end

  create_table "standard_id_identifiers", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "type", null: false
    t.string "value", null: false
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "type", "value"], name: "index_standard_id_identifiers_on_account_id_and_type_and_value", unique: true
    t.index ["account_id"], name: "index_standard_id_identifiers_on_account_id"
  end

  create_table "standard_id_password_credentials", force: :cascade do |t|
    t.string "login", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["login"], name: "index_standard_id_password_credentials_on_login", unique: true
  end

  create_table "standard_id_sessions", force: :cascade do |t|
    t.integer "account_id", null: false
    t.string "type", null: false
    t.string "lookup_hash", null: false
    t.string "token_digest", null: false
    t.string "ip_address"
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.text "user_agent"
    t.string "device_id"
    t.text "device_agent"
    t.datetime "last_refreshed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "type", "expires_at"], name: "idx_on_account_id_type_expires_at_fed5f68be5"
    t.index ["account_id"], name: "index_standard_id_sessions_on_account_id"
    t.index ["expires_at", "revoked_at"], name: "index_standard_id_sessions_on_expires_at_and_revoked_at"
    t.index ["lookup_hash", "expires_at", "revoked_at"], name: "idx_on_lookup_hash_expires_at_revoked_at_34a4504c19"
    t.index ["lookup_hash"], name: "index_standard_id_sessions_on_lookup_hash", unique: true
    t.index ["type"], name: "index_standard_id_sessions_on_type"
  end

  add_foreign_key "standard_id_credentials", "standard_id_identifiers", column: "identifier_id"
  add_foreign_key "standard_id_identifiers", "accounts"
  add_foreign_key "standard_id_sessions", "accounts"
end
