class AddUseProgressUpdatesToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :use_progress_updates, :boolean, null: false
  end
end
