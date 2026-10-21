class AddGithubTrackingEnabledToCourses < ActiveRecord::Migration[8.0]
  def change
    add_column :courses, :github_tracking_enabled, :boolean, default: false, null: false
  end
end
