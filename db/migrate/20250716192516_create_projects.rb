class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :enrolment, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.references :ownership, null: false, foreign_key: true
      t.string :proposal, null: false
      t.integer :status, null: false, default: 0
      
      t.timestamps
    end
  end
end
