class FixDirectInviteSenderUniqueIndex < ActiveRecord::Migration[8.0]
  def change
    remove_index :project_group_invites, name: "idx_pgi_unique_pending_sender_group_kind"

    add_index :project_group_invites,
              %i[sender_id project_group_id kind],
              unique: true,
              where: "status = 0 AND kind = 0",
              name: "idx_pgi_unique_pending_sender_group_kind"
  end
end