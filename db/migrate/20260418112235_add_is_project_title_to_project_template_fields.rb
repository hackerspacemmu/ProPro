class AddIsProjectTitleToProjectTemplateFields < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:project_template_fields, :is_project_title)
      add_column :project_template_fields, :is_project_title, :boolean, default: false, null: false
    end

    ProjectTemplateField.unscoped
      .where(label: 'Project Title')
      .update_all(is_project_title: true)
  end

  def down
    remove_column :project_template_fields, :is_project_title
  end
end
