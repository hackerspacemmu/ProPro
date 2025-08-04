class ProjectGroup < ApplicationRecord
    has_many :project_group_members
    belongs_to :course

    has_many :users, through: :project_group_members
end
