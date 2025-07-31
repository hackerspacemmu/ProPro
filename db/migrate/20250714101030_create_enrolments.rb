class CreateEnrolments < ActiveRecord::Migration[8.0]
  def change
    create_table :enrolments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :role, null: false

      t.timestamps
    end
  end
end
