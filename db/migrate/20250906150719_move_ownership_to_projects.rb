class MoveOwnershipToProjects < ActiveRecord::Migration[8.0]
  class Project < ApplicationRecord
    belongs_to :ownership
    enum :ownership_type, { student: 0, project_group: 1, lecturer: 2 }
  end

  def up
    ActiveRecord::Base.transaction do
      add_reference :projects, :owner, null: true, polymorphic: true
      add_column :projects, :ownership_type, :integer, null: true

      Project.find_each do |project|
        tmp = project.ownership
        project.update_columns(owner_id: tmp.owner_id, ownership_type: tmp.ownership_type, owner_type: tmp.owner_type)
      end
    end
  end
end
