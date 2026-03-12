class CreateStandardIdConsentGrants < ActiveRecord::Migration[8.0]
  def change
    create_table :standard_id_consent_grants, id: primary_key_type do |t|
      t.references :account, null: false, type: foreign_key_type
      t.references :client_application, null: false, type: foreign_key_type

      t.string :scopes, null: false
      t.datetime :granted_at, null: false
      t.datetime :revoked_at

      t.timestamps
    end

    add_index :standard_id_consent_grants,
      [:account_id, :client_application_id],
      unique: true,
      where: "revoked_at IS NULL",
      name: "idx_consent_grants_active_unique"
  end
end
