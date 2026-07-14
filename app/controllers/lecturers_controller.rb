class LecturersController < ApplicationController
  before_action :set_course

  def index
    @lecturers = @course.lecturers
    @capacity_result = SupervisorCapacityCalculator.new(@course).calculate
    @lecturer_capacity_info = @capacity_result.lecturer_capacities.index_by { |lc| lc.enrolment.user_id }
    @from_new_project = params[:from_new_project].present?
  end

  def show
    @lecturers = @course.lecturers
    coordinator_enrolment = @course.enrolments.find_by(user_id: params[:id], role: :coordinator)
    @lecturer_enrolment = @course.enrolments.find_by(user_id: params[:id], role: :lecturer)

    @enrolment = coordinator_enrolment || @lecturer_enrolment

    @lecturer = @enrolment.user

    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
    @is_coordinator = @current_user_enrolment&.coordinator?
    @is_student = @current_user_enrolment&.student?
    @is_lecturer = @current_user_enrolment&.lecturer?

    unless @enrolment&.role.in?(%w[lecturer coordinator])
      redirect_to course_lecturers_path(@course), alert: 'Not a lecturer.'
      return
    end

    # set current user's projects for Propose to Lecturer
    @project = if @course.grouped?
                 group = current_user.project_groups.find_by(course: @course)
                 @course.projects.find_by(owner: group) if group
               else
                 @course.projects.find_by(owner: current_user)
               end

    set_supervised_projects
    set_lecturer_topics
  end

  def promote_to_coordinator
    return unless @course.coordinators.include?(Current.user)

    new_coordinator = User.find(params[:id])
    Enrolment.find_or_create_by!(
      user: new_coordinator,
      course: @course,
      role: :coordinator
    )
    redirect_to course_lecturer_path(@course, new_coordinator)
  end

  def demote_to_lecturer
    return unless @course.coordinators.include?(Current.user)

    new_coordinator = User.find(params[:id])
    coordinator_enrolment = Enrolment.find_by(
      user: new_coordinator,
      course: @course,
      role: :coordinator
    )
    coordinator_enrolment&.destroy
    redirect_to course_lecturer_path(@course, new_coordinator)
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_supervised_projects
    if @lecturer_enrolment
      @my_student_projects = Project.where(course: @course)
                                    .supervised_by(@lecturer_enrolment)
                                    .approved
      @incoming_proposals = Project.where(course: @course)
                                   .supervised_by(@lecturer_enrolment)
                                   .proposals
    else
      @my_student_projects = []
      @incoming_proposals = []
    end
  end

  def set_lecturer_topics
    if @lecturer_enrolment
      topics = @course.topics.where(owner: @lecturer)
      @approved_topics = topics.approved
      @pending_topics = topics.proposals
    else
      @approved_topics = []
      @pending_topics = []
    end
  end
end
