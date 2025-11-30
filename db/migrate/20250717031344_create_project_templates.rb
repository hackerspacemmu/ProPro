class CreateProjectTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :project_templates do |t|
      t.references :course, null: false, foreign_key: true

      t.timestamps
    end
  end
end
