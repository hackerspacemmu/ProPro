class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email_address, null: false
      t.string :password_digest, null: true
      t.string :username, null: false
      t.boolean :has_registered, null: false
      t.string :student_id, null: true
      t.string :mmu_directory, null: true
      t.boolean :is_staff, null: false

      t.timestamps
    end
    add_index :users, :email_address, unique: true
  end
end
