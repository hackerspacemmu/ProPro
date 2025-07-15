class ProjectGroupMember < ApplicationRecord
  belongs_to :user
  belongs_to :course
  belongs_to :project_group
end
