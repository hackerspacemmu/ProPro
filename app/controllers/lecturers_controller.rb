class LecturersController < ApplicationController

before_action :set_course

def index
end

def show
  @enrolment = @course.enrolments.find_by(user_id: params[:id], role: [:lecturer, :coordinator])
  @lecturer = @enrolment&.user

  unless @enrolment&.role.in?(%w[lecturer coordinator])
    redirect_to course_lecturers_path(@course), alert: "Not a lecturer."
    return
  end

  # All approved projects for this lecturer
  @approved_projects = @course.projects.where(enrolment: @enrolment, status: :approved)
end

private

def set_course
  @courses = Current.user.courses
  @course = Course.find(params[:course_id])
  @lecturers = @course.lecturers.includes(:user).map(&:user)
end
end
