class CreateProjectGroupInviteLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :project_group_invite_links do |t|
      t.references :project_group, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.string :token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :project_group_invite_links, :token, unique: true
  end
end