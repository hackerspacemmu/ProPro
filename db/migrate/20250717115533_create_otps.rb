class CreateOtps < ActiveRecord::Migration[8.0]
  def change
    create_table :otps do |t|
      t.string :email_address, null: false
      t.string :otp, null: false

      t.timestamps
    end
  end
end
