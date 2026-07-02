class AddSourceTopicToTopics < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :source_topic_id, :integer
    add_column :project_instance_fields, :source_field_id, :integer
    add_index :project_instance_fields, :source_field_id
  end
end
