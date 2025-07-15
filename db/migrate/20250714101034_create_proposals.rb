class CreateProposals < ActiveRecord::Migration[8.0]
  def change
    create_table :proposals do |t|
      t.references :enrolment, null: false, foreign_key: true
      t.references :project_group, null: false, foreign_key: true
      t.string :student_proposal, null: false
      t.string :feedback, null: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
