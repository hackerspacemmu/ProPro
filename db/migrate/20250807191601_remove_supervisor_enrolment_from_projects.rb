class RemoveSupervisorEnrolmentFromProjects < ActiveRecord::Migration[8.0]
  def change
    remove_column :projects, :supervisor_enrolment_id, :integer
  end
end
