class AddTokenAndExpiresAtToProjectGroupInvites < ActiveRecord::Migration[8.0]
  def change
    add_column :project_group_invites, :token, :string
    add_column :project_group_invites, :expires_at, :datetime
    add_index :project_group_invites, :token, unique: true
  end
end