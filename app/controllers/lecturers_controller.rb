class LecturersController < ApplicationController
  before_action :set_course
  before_action :set_lecturer, only: %i[show promote_to_coordinator demote_to_lecturer]

  def index; end

  def show
    @lecturers = @course.lecturers
    coordinator_enrolment = @course.enrolments.find_by(user_id: @lecturer.id, role: :coordinator)
    @lecturer_enrolment = @course.enrolments.find_by(user_id: @lecturer.id, role: :lecturer)

    @enrolment = coordinator_enrolment || @lecturer_enrolment

    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
    @is_coordinator = @current_user_enrolment&.coordinator?
    @is_student = @current_user_enrolment&.student?
    @is_lecturer = @current_user_enrolment&.lecturer?

    unless @enrolment&.role.in?(%w[lecturer coordinator])
      redirect_to course_lecturers_path(@course), alert: 'Not a lecturer.'
      return
    end

    set_supervised_projects
    set_lecturer_topics
  end

  def promote_to_coordinator
    authorize @course, :promote_to_coordinator?

    enrolment = Enrolment.find_by(user: @lecturer, course: @course)

    if enrolment
      enrolment.update!(role: :coordinator)
    else
      Enrolment.create!(user: @lecturer, course: @course, role: :coordinator)
    end

    redirect_to course_lecturer_path(@course, @lecturer), status: :see_other
  end

  def demote_to_lecturer
    authorize @course, :demote_to_lecturer?

    enrolment = Enrolment.find_by(user: @lecturer, course: @course)

    if enrolment
      enrolment.update!(role: :lecturer)
    else
      Enrolment.create!(user: @lecturer, course: @course, role: :lecturer)
    end

    redirect_to course_lecturer_path(@course, @lecturer), status: :see_other
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_lecturer
    @lecturer = User.find(params[:id])
  end

  def set_supervised_projects
    if @lecturer_enrolment
      projects = Pundit.policy_scope!(current_user, Project.where(course: @course))
      @my_student_projects = projects.supervised_by(@lecturer_enrolment).approved
      @incoming_proposals = projects.supervised_by(@lecturer_enrolment).proposals
    else
      @my_student_projects = []
      @incoming_proposals = []
    end
  end

  def set_lecturer_topics
    if @lecturer_enrolment
      topics = @course.topics.where(owner: @lecturer)
      @approved_topics = policy_scope(topics).approved
      @pending_topics = policy_scope(topics).proposals
    else
      @approved_topics = []
      @pending_topics = []
    end
  end
end
