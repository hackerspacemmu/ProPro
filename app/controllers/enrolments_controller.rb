class EnrolmentsController < ApplicationController
  def destroy
    params.require(%i[course_id id])

    current_course = Course.find(params[:course_id])
    enrolment = current_course.enrolments.find(params[:id])

    # Authorization is on the authenticated user, never on a client-submitted id.
    unless current_course.coordinator_ids.include?(current_user.id)
      redirect_back_or_to dashboard_path, alert: 'You are not authorized to perform this action.'
      return
    end

    if current_course.grouped?
      group_member = ProjectGroupMember.joins(:project_group)
                                       .find_by(project_groups: { course_id: current_course.id },
                                                user_id: enrolment.user_id)

      if group_member
        # Enrolment removal supplies the confirmation itself for now; the shared
        # warning path arrives with the enrolment transaction work.
        result = Groups::Coordinator::MemberRemover.new(group_member, confirm: true).remove!

        if result.blocked?
          redirect_back_or_to course_path(current_course), alert: result.message
          return
        end
      end
    end

    enrolment.destroy!
    redirect_to course_path(current_course), notice: 'Student removed from course.'
  rescue ActiveRecord::RecordNotFound
    redirect_back_or_to dashboard_path, alert: 'Record not found.'
  end
end
