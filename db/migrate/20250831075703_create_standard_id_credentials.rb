class CreateStandardIdCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :standard_id_credentials, id: primary_key_type do |t|
      t.references :identifier, null: false, foreign_key: { to_table: :standard_id_identifiers }, index: true
      t.references :credentialable, null: false, polymorphic: true, index: true

      t.timestamps
    end
  end
end
