class LecturersController < ApplicationController

  before_action :set_course

  def index
  end

  def show
    @enrolment = @course.enrolments.find_by(user_id: params[:id], role: [:lecturer, :coordinator])
    @lecturer  = @enrolment&.user

    unless @enrolment&.role.in?(%w[lecturer coordinator])
      redirect_to course_lecturers_path(@course), alert: "Not a lecturer."
      return
    end

    # All approved projects for this lecturer
    @approved_projects = if @course.enrolments.exists?(user: Current.user, role: :coordinator)
      @course.projects.joins(:ownership).where(
          ownerships: {
            owner_type:  "User",
            owner_id:    @lecturer.id,
            ownership_type: :lecturer
          }
        )
    else
      @course.projects.joins(:ownership).where(
          ownerships: {
            owner_type:  "User",
            owner_id:    @lecturer.id,
            ownership_type: :lecturer
          }
        ).where(status: :approved)
    end

    @not_approved_projects = @course.projects.joins(:ownership).where(
          ownerships: {
            owner_type:  "User",
            owner_id:    @lecturer.id,
            ownership_type: :lecturer
          },  
        projects: {status: ["pending", "rejected", "redo"]}
        )
  end

  private

  def set_course
    @courses   = Current.user.courses
    @course    = Course.find(params[:course_id])
    @lecturers = @course.lecturers.includes(:user).map(&:user)
  end
end
