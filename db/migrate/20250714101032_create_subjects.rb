class CreateSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :subjects do |t|
      t.string :subject_name, null: false
      t.integer :number_of_updates, null: false
      t.integer :starting_week, null: false
      t.boolean :restricted_view, null: false
      t.string :topic_suggestions, null: true

      t.timestamps
    end
  end
end
