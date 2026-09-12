class EnrolmentsController < ApplicationController
  def destroy
    params.require(%i[course_id id])

    current_course = Course.find(params[:course_id])

    # Authorization is on the authenticated user, never on a client-submitted id.
    unless current_course.coordinator_ids.include?(current_user.id)
      redirect_back_or_to '/'
      return
    end

    enrolment = current_course.enrolments.find(params[:id])
    user_id = enrolment.user_id

    begin
      ActiveRecord::Base.transaction do
        if current_course.grouped
          project_group = ProjectGroup.includes(:project_group_members).find_by!(
            course_id: params[:course_id], project_group_members: { user_id: user_id }
          )

          group_member = project_group.project_group_members.find_by!(user_id: user_id)

          group_member.destroy!

          if project_group.project_group_members.count <= 0
            project_group.destroy!
            true
          end
        end

        enrolment.destroy!
      end
    rescue StandardError
      redirect_to participant_profile_course_path(params[:course_id], user_id, 'student')
    end

    redirect_to course_path(params[:course_id])
  end
end
