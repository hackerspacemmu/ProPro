class ProjectInstanceField < ApplicationRecord
    belongs_to :instance, polymorphic: true
    belongs_to :project_template_field
end
