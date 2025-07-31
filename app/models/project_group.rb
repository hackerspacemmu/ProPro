class ProjectGroup < ApplicationRecord
    has_many :project_group_members
    belongs_to :course
end
