class AddSourceTopic < ActiveRecord::Migration[8.0]
  def change
    add_reference :projects, :source_topic, index: true, null: true
    add_reference :project_instances, :source_topic, index: true, null: true
  end
end
