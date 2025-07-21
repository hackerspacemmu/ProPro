class DeleteIsPrimaryFromProjectInstanceFields < ActiveRecord::Migration[8.0]
  def change
    remove_column :project_template_fields, :is_primary_title, :boolean
  end
end
