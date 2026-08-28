class RemoveOtpFromOtp < ActiveRecord::Migration[8.0]
  def change
    remove_column :otps, :otp, :string
  end
end
