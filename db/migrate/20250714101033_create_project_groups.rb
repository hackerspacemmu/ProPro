class CreateProjectGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :project_groups do |t|
      t.references :course, null: false
      t.string :group_name, null: false

      t.timestamps
    end
  end
end
