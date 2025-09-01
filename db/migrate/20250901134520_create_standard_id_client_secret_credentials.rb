class CreateStandardIdClientSecretCredentials < ActiveRecord::Migration[7.1]
  def change
    create_table :standard_id_client_secret_credentials do |t|
      t.string :name, null: false

      t.string :client_id, null: false, index: { unique: true }
      t.string :client_secret_digest, null: false

      t.string :scopes

      t.boolean :active, null: false, default: true
      t.datetime :revoked_at

      t.timestamps
    end
  end
end
