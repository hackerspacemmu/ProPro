class CreateProposals < ActiveRecord::Migration[8.0]
  def change
    create_table :proposals do |t|
      t.references :enrolment, null: false, foreign_key: true
      t.references :owner, polymorphic: true, null: false
      t.string :proposal, null: false
      t.string :feedback, null: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
