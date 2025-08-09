class TopicResponses < ApplicationRecord
  belongs_to :project
  has_many :project_instances
end
