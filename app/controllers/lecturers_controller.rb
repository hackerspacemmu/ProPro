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
    coordinators = @course.coordinators

    unless coordinators.include? Current.user
      return
    end
 
    new_coordinator = User.find(params[:id])

    Enrolment.find_or_create_by!(
      user: new_coordinator,
      course: @course,
      role: :coordinator
    )
    
    redirect_to course_lecturer_path(@course, new_coordinator)
  end

  def demote_to_lecturer
    coordinators = @course.coordinators

    if coordinators.count == 1
      return
    end

    unless coordinators.include? Current.user
      return
    end

    new_coordinator = User.find(params[:id])

    coordinator_enrolment = Enrolment.find_by(
      user: new_coordinator,
      course: @course,
      role: :coordinator
    )

    if coordinator_enrolment
      coordinator_enrolment.destroy
    end

    redirect_to course_lecturer_path(@course, new_coordinator)
  end
  
  private
  
  def set_course
    @course = Course.find(params[:course_id])
  end
  
  def set_supervised_projects
    return set_empty_projects unless @lecturer_enrolment
    
    @my_student_projects = policy_scope(@course.projects.supervised_by(@lecturer_enrolment).approved)
    @incoming_proposals = policy_scope(@course.projects.supervised_by(@lecturer_enrolment).proposals)
  end

  def set_lecturer_topics
    return set_empty_topics unless @lecturer_enrolment

    topics = @course.topics.where(owner: @lecturer)
    
    @approved_topics = policy_scope(topics).approved
    @pending_topics = policy_scope(topics).proposals
  end

  def set_empty_projects
    @my_student_projects = []
    @incoming_proposals = []
  end

  def set_empty_topics
    @approved_topics = []
    @pending_topics = []
  end
end
