class AddVerifyOnlyToOtp < ActiveRecord::Migration[8.0]
  def change
    add_column :otps, :verify_only, :boolean, default: false, null: false
  end
end
