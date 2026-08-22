class AddDissolvedAtToProjectGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :project_groups, :dissolved_at, :datetime
  end
end