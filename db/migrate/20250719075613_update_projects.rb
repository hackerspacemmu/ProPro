class UpdateProjects < ActiveRecord::Migration[8.0]
  def change
    remove_column :projects, :proposal, :string
    remove_column :projects, :title, :string 
    remove_column :project_templates, :is_primary_title, :boolean
    add_column :project_templates, :description, :string
    add_column :project_instances, :title, :string, :null => false
  end
end
