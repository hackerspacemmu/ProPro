class CreateTopicResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :topic_responses do |t|
      t.references :project, null: false, foreign_key: true
      t.references :project_instance, null: false, foreign_key: true

      t.timestamps
    end
  end
end
