class ReshapeProjectGroupInvites < ActiveRecord::Migration[8.0]
  def change
    remove_index :project_group_invites, :token
    remove_column :project_group_invites, :token, :string
    remove_column :project_group_invites, :expires_at, :datetime

    add_column :project_group_invites, :recipient_id, :integer, null: false
    add_foreign_key :project_group_invites, :users, column: :recipient_id
    add_index :project_group_invites, :recipient_id

    # Blocks a leader double-inviting same student into same group.
    add_index :project_group_invites,
              %i[recipient_id project_group_id kind],
              unique: true,
              where: "status = 0 AND kind = 1",
              name: "idx_pgi_unique_pending_recipient_group_kind"
  end
end
