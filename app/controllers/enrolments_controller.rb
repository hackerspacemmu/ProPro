class EnrolmentsController < ApplicationController
  def destroy
    params.require([:coordinator_id, :course_id, :id])

    current_course = Course.find(params[:course_id])
    course_coordinators = current_course.coordinators.pluck(:id)

    unless course_coordinators.include?(params[:coordinator_id].to_i)
      redirect_back_or_to "/"
      return
    end

    enrolment = Enrolment.find_by!(id: params[:id])
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
            group_deleted = true
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
