class LecturersController < ApplicationController
  before_action :set_course
  
  def index
  end
  
  def show
    @lecturers = @course.lecturers
    coordinator_enrolment = @course.enrolments.find_by(user_id: params[:id], role: :coordinator)
    @lecturer_enrolment = @course.enrolments.find_by(user_id: params[:id], role: :lecturer)

    coordinator_enrolment ? @enrolment = coordinator_enrolment : @enrolment = @lecturer_enrolment

    @lecturer = @enrolment.user
    
    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
    @is_coordinator = @current_user_enrolment&.coordinator?
    @is_student = @current_user_enrolment&.student?
    @is_lecturer = @current_user_enrolment&.lecturer?
    
    unless @enrolment&.role.in?(%w[lecturer coordinator])
      redirect_to course_lecturers_path(@course), alert: "Not a lecturer."
      return
    end
  
    set_supervised_projects
    set_lecturer_topics
  end
  
  def promote_to_coordinator
    authorize @course, :promote_to_coordinator?

    Enrolment.find_or_create_by!(
      user: new_coordinator,
      course: @course,
      role: :coordinator
    )
    
    redirect_to course_lecturer_path(@course, new_coordinator)
  end

  def demote_to_lecturer
    authorize @course, :demote_to_lecturer?

    coordinator_enrolment = Enrolment.find_by(
      user: new_coordinator,
      course: @course,
      role: :coordinator
    )
    
    redirect_to course_lecturer_path(@course, new_coordinator)
  end
  
  private
  
  def set_course
    @course = Course.find(params[:course_id])
  end
  
  def set_supervised_projects
    if @lecturer_enrolment
      projects = Pundit.policy_scope!(current_user, Project.where(course: @course))
      @my_student_projects = projects.supervised_by(@lecturer_enrolment).approved
      @incoming_projects = projects.supervised_by(@lecturer_enrolment).proposals
    else
      @my_student_projects = []
      @incoming_projects = []
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
