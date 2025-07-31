class CreateProgressUpdates < ActiveRecord::Migration[8.0]
  def change
    create_table :progress_updates do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :rating, null: false
      t.string :feedback, null: false

      t.timestamps
    end
  end
end
