class EnrolmentsController < ApplicationController
  def destroy
    current_course = Course.find(params[:course_id])
    enrolment = current_course.enrolments.find(params[:id])

    unless current_course.coordinator_ids.include?(current_user.id)
      redirect_back fallback_location: root_path, alert: 'You are not authorized to perform this action.'
      return
    end

    if current_course.grouped?
      group_member = ProjectGroupMember.joins(:project_group)
                                        .find_by(project_groups: { course_id: current_course.id },
                                                user_id: enrolment.user_id)

      if group_member
        result = GroupMemberRemover.new(group_member, current_user: current_user, dissolve_confirmed: true).remove!

        if result.blocked?
          redirect_back fallback_location: course_path(current_course), alert: result.message
          return
        end
      end
    end

    enrolment.destroy!
    redirect_to course_path(current_course), notice: 'Student removed from course.'
  rescue ActiveRecord::RecordNotFound
    redirect_back fallback_location: root_path, alert: 'Record not found.'
  end
end
