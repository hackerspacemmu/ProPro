class CreateProjectInstanceFields < ActiveRecord::Migration[8.0]
  def change
    create_table :project_instance_fields do |t|
      t.references :project_instance,       null: false, foreign_key: true
      t.references :project_template_field, null: false, foreign_key: true
      t.text       :value

      t.timestamps
    end
    add_index :project_instance_fields, %i[project_instance_id project_template_field_id], unique: true,
                                                                                           name: 'index_project_instance_fields_on_instance_and_template_field'
  end
end
