class ProjectGroupInviteLink < ApplicationRecord
  belongs_to :project_group
  belongs_to :sender, class_name: 'User'
end