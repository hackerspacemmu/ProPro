class CreateProjectTemplateFields < ActiveRecord::Migration[8.0]
  def change
    create_table :project_template_fields do |t|
      t.references :project_template, null: false, foreign_key: true
      t.integer :field_type, null: false
      t.integer :applicable_to, null: false
      t.string :label, null: false
      t.text :hint
      t.json :options 

      t.timestamps
    end
  end 
end
  