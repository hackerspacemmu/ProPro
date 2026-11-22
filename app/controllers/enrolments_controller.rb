# Removes student enrolments, confirming first when a proposal would be deleted.
class EnrolmentsController < ApplicationController
  before_action :set_course_and_enrolment
  before_action :require_coordinator

  def destroy
    result = Groups::Coordinator::EnrolmentRemover.new(
      @enrolment,
      confirm: params[:confirm] == 'true'
    ).remove!

    if result.needs_confirmation?
      redirect_to confirm_removal_enrolment_path(@enrolment, course_id: @course.id)
    else
      redirect_to course_path(@course), notice: result.message
    end
  end

  def confirm_removal
    @student = @enrolment.user
    @membership = @course.project_group_members.find_by(user_id: @student.id)
    @project_title = project_title_for_confirmation
  end

  private

  def set_course_and_enrolment
    @course = Course.find(params[:course_id])
    @enrolment = @course.enrolments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_back_or_to dashboard_path, alert: 'Record not found.'
  end

  def require_coordinator
    return if performed?
    return if @course.coordinator_ids.include?(current_user.id)

    redirect_back_or_to dashboard_path, alert: 'You are not authorized to perform this action.'
  end

  def project_title_for_confirmation
    group = @membership&.project_group
    return unless group
    return unless group.project_group_members.one?

    group.project&.current_title
  end
end
