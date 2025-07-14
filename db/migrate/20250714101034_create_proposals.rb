class CreateProposals < ActiveRecord::Migration[8.0]
  def change
    create_table :proposals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.string :student_proposal, null: false
      t.string :instructor_feedback, null: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
