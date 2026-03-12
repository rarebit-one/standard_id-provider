class CreateStandardIdRevokedTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :standard_id_revoked_tokens, id: primary_key_type do |t|
      t.string :jti, null: false
      t.string :token_type
      t.string :client_id
      t.datetime :revoked_at, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :standard_id_revoked_tokens, :jti, unique: true
    add_index :standard_id_revoked_tokens, :expires_at
  end
end
