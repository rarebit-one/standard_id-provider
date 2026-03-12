class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :email, null: false, index: { unique: true }
      t.string :name, null: false
      t.timestamps
    end
  end
end
