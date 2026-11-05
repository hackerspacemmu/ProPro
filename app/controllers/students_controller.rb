# The Students tab for solo-project courses — /courses/:course_id/students.
# It mirrors the Groups tab's project-oriented directory while keeping the
# People tab focused on lecturers. Grouped courses use People + Groups instead.
class StudentsController < ApplicationController
  include ParticipantBrowsing

  before_action :set_course
  before_action :authorize_course
  before_action :ensure_solo

  def index
    projects = @course.projects
                      .where(owner_type: 'User')
                      .includes(supervisor_enrolment: :user,
                                project_instances: { supervisor_enrolment: :user })
                      .load
    @projects_by_owner = projects.index_by { |project| ['User', project.owner_id] }

    @student_list = @course.students
    @filtered_student_list = filtered_student_list
    @show_all = params[:show_all] == 'true'
    @total_student_count = @filtered_student_list.count
    unless @show_all
      @filtered_student_list = @filtered_student_list.first(
        Rails.application.config.participants_pagination_threshold
      )
    end

    @student_list_state = list_state(@student_list, @filtered_student_list)

    return unless request.headers['HX-Request']

    render partial: 'courses/solo_students_table',
           locals: {
             course: @course,
             students: @filtered_student_list,
             projects_by_owner: @projects_by_owner,
             total_count: @total_student_count,
             displayed_count: @filtered_student_list.count,
             show_all: @show_all,
             state: @student_list_state
           }
    nil
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
  end

  def authorize_course
    authorize @course, :show?
  end

  def ensure_solo
    raise ActiveRecord::RecordNotFound if @course.grouped?
  end
end
