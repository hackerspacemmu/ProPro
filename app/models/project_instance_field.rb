class ProjectInstanceField < ApplicationRecord
    belongs_to :project_instance
    belongs_to :project_template_field
end
