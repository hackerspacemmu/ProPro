# Records whether a group came from the formation UI or a CSV import.
class AddOriginToProjectGroups < ActiveRecord::Migration[8.0]
  def change
    add_column :project_groups, :origin, :string, default: 'formation', null: false
  end
end
