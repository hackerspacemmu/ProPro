class ProjectInstanceField < ApplicationRecord
    belongs_to :project_instance
    belongs_to :topic_instance, class_name: "TopicInstance", foreign_key: "project_instance_id"
    belongs_to :project_template_field
end
