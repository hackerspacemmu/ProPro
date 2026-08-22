class CreateProjectGroupInvites < ActiveRecord::Migration[8.0]
  def change
    create_table :project_group_invites do |t|
      t.references :project_group, null: false, foreign_key: true
      t.references :sender,        null: false, foreign_key: { to_table: :users }
      t.integer    :kind,          null: false, default: 0
      t.integer    :status,        null: false, default: 0

      t.timestamps
    end

    # One pending request per sender per group per kind.
    # Partial index: allows a new request after a prior one was declined.
    add_index :project_group_invites,
              [:sender_id, :project_group_id, :kind],
              unique: true,
              where: "status = 0",
              name: "idx_pgi_unique_pending_sender_group_kind"
  end
end
