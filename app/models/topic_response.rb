class TopicResponse < ApplicationRecord
  belongs_to :project
  belongs_to :project_instance
end
