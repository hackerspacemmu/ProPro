class AddClaimUuidToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :claim_uuid, :string, null: true
    add_index :users, :claim_uuid, unique: true
  end
end
