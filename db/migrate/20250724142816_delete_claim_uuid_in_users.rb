class DeleteClaimUuidInUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :claim_uuid
    remove_column :otps, :email_address

    add_column :otps, :token, :string, null: false
    add_reference :otps, :user, null: false, foreign_key: true
  end
end
