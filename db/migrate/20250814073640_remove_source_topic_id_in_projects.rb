class RemoveSourceTopicIdInProjects < ActiveRecord::Migration[8.0]
  def change
    remove_reference :projects, :source_topic
  end
end
