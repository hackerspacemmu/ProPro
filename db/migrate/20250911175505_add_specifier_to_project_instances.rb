class AddSpecifierToProjectInstances < ActiveRecord::Migration[8.0]
  class ProjectInstance < ApplicationRecord
    belongs_to :project
    enum :type, { topic: 0, project: 1 }
  end

  def up
    ActiveRecord::Base.transaction do
      add_column :project_instances, :type, :integer, null: true

      ProjectInstance.find_each do |project_instance|
        topic = Topic.find_by(id: project_instance.project_id)
        project = Project.find_by(id: project_instance.project_id)

        if (topic && !project)
          project_instance.update_columns(type: :topic)
        elsif (project && !topic)
          project_instance.update_columns(type: :project)
        else
          raise StandardError
        end
      end

      change_column_null :project_instances, :type, false
      change_column_null :project_instances, :enrolment_id, true
    end
  end
end
