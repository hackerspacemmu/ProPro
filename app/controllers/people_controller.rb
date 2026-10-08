# The People tab — /courses/:course_id/people (route-per-tab, ADR 0019).
# One page: the Lecturers half (with the supervisor capacity strip) plus the
# Students half, and the htmx branch that used to be courses#show's
# `section=students` dispatch (same partial, same locals).
class PeopleController < ApplicationController
  include ParticipantBrowsing

  before_action :set_course
  before_action :authorize_course

  def index
    projects = @course.projects.includes(project_instances: { supervisor_enrolment: :user }).load
    @projects_by_owner = projects.index_by { |p| [p.owner_type, p.owner_id] }

    @student_list = @course.students
    @lecturers = @course.lecturers

    @capacity_result = SupervisorCapacityCalculator.new(@course).calculate
    @lecturer_capacity_info = @capacity_result.lecturer_capacities.index_by { |lc| lc.enrolment.user_id }

    # One map lookup, computed once: user_id => project_group for the Students
    # section's Group column. Includes draft groups (students in a draft group
    # still belong to it); excludes nothing that is an actual membership.
    @student_group_map = {}
    if @course.grouped?
      @course.project_groups.includes(project_group_members: :user).find_each do |group|
        group.project_group_members.each { |member| @student_group_map[member.user_id] = group }
      end
    end

    # One map lookup for the Students section's Remove-from-course action.
    @student_enrolment_map = @course.enrolments.where(role: :student).index_by(&:user_id)

    @filtered_student_list = filtered_student_list
    @show_all = params[:show_all] == 'true'
    # Counts the matches, taken before the truncation below: the table footer's
    # "Showing X of Y" is about the current criteria, not the course total.
    @total_student_count = @filtered_student_list.count
    @filtered_student_list = @filtered_student_list.first(Rails.application.config.participants_pagination_threshold) unless @show_all

    # Empty vs no-matches, decided here rather than in the partials (ADR 0018).
    @student_list_state = list_state(@student_list, @filtered_student_list)
    # The filter controls sit outside the htmx-swapped containers, so the
    # partials are told a filter is active rather than re-deriving it from params.
    @filters_active = filters_active?(PARTICIPANT_FILTER_KEYS)

    return unless request.headers['HX-Request']

    render partial: 'courses/students_table',
           locals: {
             course: @course,
             students: @filtered_student_list,
             student_group_map: @student_group_map,
             student_enrolment_map: @student_enrolment_map,
             total_student_count: @student_list.count,
             total_count: @total_student_count,
             displayed_count: @filtered_student_list.count,
             show_all: @show_all,
             state: @student_list_state,
             filters_active: @filters_active
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
end
