class AddPositionToProjectTemplateField < ActiveRecord::Migration[8.0]
  def up
    add_column :project_template_fields, :position, :integer

    # Refresh schema cache so the model recognizes the new column
    ProjectTemplateField.reset_column_information

    ProjectTemplate.find_each do |template|
      fields = template.project_template_fields.order(:created_at)
      fields.each_with_index do |field, index|
        field.update_column(:position, index + 1)
      end
    end

    # Add constraints after population
    change_column_null :project_template_fields, :position, false

    add_index :project_template_fields, [:project_template_id, :position], unique: true
  end

  def down
    remove_index :project_template_fields, [:project_template_id, :position]
    remove_column :project_template_fields, :position
  end
end