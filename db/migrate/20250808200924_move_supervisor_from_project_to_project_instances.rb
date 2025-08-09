class MoveSupervisorFromProjectToProjectInstances < ActiveRecord::Migration[8.0]
  def up
    ActiveRecord::Base.transaction do
      add_reference :project_instances, :enrolment, foreign_key: true, null: true

      ProjectInstance.find_each do |project_instance|
        project_instance.update_columns(enrolment_id: project_instance.project.enrolment_id)
      end

      change_column_null :project_instances, :enrolment_id, false
    end
  end
end
