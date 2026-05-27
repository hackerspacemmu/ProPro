class BackfillSupervisorEnrolmentsToLecturer < ActiveRecord::Migration[8.0]
  def up
    # Backfill Project
    Project.joins(:supervisor_enrolment).where(enrolments: { role: :coordinator }).each do |project|
      lecturer_enrolment = Enrolment.find_by(
        user_id: project.supervisor_enrolment.user_id,
        course_id: project.course_id,
        role: :lecturer
      )
      next unless lecturer_enrolment
      project.update_columns(supervisor_enrolment_id: lecturer_enrolment.id)
    end

    # Backfill ProjectInstance
    ProjectInstance.joins(:supervisor_enrolment)
                   .where(enrolments: { role: :coordinator })
                   .each do |instance|
      lecturer_enrolment = Enrolment.find_by(
        user_id: instance.supervisor_enrolment.user_id,
        course_id: instance.course_id,
        role: :lecturer
      )
      next unless lecturer_enrolment
      instance.update_columns(supervisor_enrolment_id: lecturer_enrolment.id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
