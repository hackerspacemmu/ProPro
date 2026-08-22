class RemoveDissolvedAtFromProjectGroups < ActiveRecord::Migration[8.0]
  def change
    remove_column :project_groups, :dissolved_at, :datetime
  end
end