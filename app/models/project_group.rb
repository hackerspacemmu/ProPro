class ProjectGroup < ApplicationRecord
    has_many :project_group_members, dependent: :destroy
    belongs_to :course

    has_many :users, through: :project_group_members
    has_one :project, dependent: :destroy, as: :owner
end
