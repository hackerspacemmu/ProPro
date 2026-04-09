class AddFreeEditToProjectTemplateFields < ActiveRecord::Migration[8.0]
  def change
    add_column :project_template_fields, :free_edit, :boolean, default: false, null: false
  end
end