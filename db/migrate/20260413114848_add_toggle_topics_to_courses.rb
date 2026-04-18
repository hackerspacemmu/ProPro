class AddToggleTopicsToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :toggle_topics, :boolean,  default: true
  end
end
