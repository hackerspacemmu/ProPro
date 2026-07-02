class AddSourceTopicToTopics < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :source_topic_id, :integer
  end
end
