class CreateStandardIdSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :standard_id_sessions, id: primary_key_type do |t|
      t.references :account, null: false, foreign_key: true, index: true

      # STI type column
      t.string :type, null: false, index: true

      # Base session columns
      t.string :lookup_hash, null: false, index: { unique: true }
      t.string :token_digest, null: false
      t.string :ip_address
      t.datetime :expires_at, null: false
      t.datetime :revoked_at

      # BrowserSession columns
      t.text :user_agent

      # DeviceSession columns
      t.string :device_id
      t.text :device_agent
      t.datetime :last_refreshed_at

      t.timestamps

      t.index [:lookup_hash, :expires_at, :revoked_at]
      t.index [:expires_at, :revoked_at]
      t.index [:account_id, :type, :expires_at]
    end
  end
end
