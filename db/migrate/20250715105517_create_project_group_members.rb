class CreateProjectGroupMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :project_group_members do |t|
      t.references :user, null: false, foreign_key: true
      t.references :project_group, null: false, foreign_key: true

      t.timestamps
    end
  end
end
