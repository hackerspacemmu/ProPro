class LecturersController < ApplicationController

  before_action :set_course

  def index
  end

  def show
    @enrolment = @course.enrolments.find_by(user_id: params[:id], role: [:lecturer, :coordinator])
    @lecturer  = @enrolment&.user

    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
    @is_coordinator = @current_user_enrolment&.coordinator?
    @is_student = @current_user_enrolment&.student?


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


    @own_approved_projects = @course.projects.joins(:ownership).where(
          ownerships: {
            owner_type:  "User",
            owner_id:    @lecturer.id,
            ownership_type: :lecturer
          },  
        projects: {status: :approved}
        )

    @not_own_approved_projects = @course.projects.joins(:ownership).where(
          ownerships: {
            owner_type:  "User",
            owner_id:    @lecturer.id,
            ownership_type: :lecturer
          },  
        projects: {status: [:redo,:rejected,:pending]}
        )
  end

  private

  def set_course
    @courses   = Current.user.courses
    @course    = Course.find(params[:course_id])
    @lecturers = @course.lecturers.includes(:user).map(&:user)
  end
end
