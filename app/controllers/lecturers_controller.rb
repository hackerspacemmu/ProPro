class LecturersController < ApplicationController
  before_action :set_course
  helper_method :access?, :own_supervisor? , :full_access?
  
  def index
  end
  
  def show
    @enrolment = @course.enrolments.find_by(user_id: params[:id], role: [:lecturer, :coordinator])
    @lecturer = @enrolment&.user
    @lecturer_enrolment = @course.enrolments.find_by(user: @lecturer, role: :lecturer)
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
  
  private
  
  def set_course
    @courses = Current.user.courses
    @course = Course.find(params[:course_id])
    @lecturers = @course.lecturers.includes(:user).map(&:user)
  end
  
  def set_supervised_projects
    return set_empty_projects unless @lecturer_enrolment
    
    base_projects = @course.projects.student_projects_for_lecturer(@lecturer_enrolment)
  
    if full_access?
      @my_student_projects = base_projects.approved
      @incoming_proposals = base_projects.proposals
    else
      @my_student_projects = filtered_projects(base_projects.approved)
      @incoming_proposals = filtered_projects(base_projects.proposals)
    end
  end

  def set_lecturer_topics
    return set_empty_topics unless @lecturer_enrolment

    lecturer_owned_topics = @course.projects.lecturer_owned.where(ownerships: { owner_type: "User", owner_id: @lecturer.id})
  
    if full_access?
      @approved_projects = lecturer_owned_topics
      @own_approved_projects = lecturer_owned_topics.where(status: :approved)
      @not_own_approved_projects = lecturer_owned_topics.where(status: [:redo, :rejected, :pending])
    else
      @approved_projects = lecturer_owned_topics.where(status: :approved)
      @own_approved_projects = lecturer_owned_topics.where(status: :approved)
      @not_own_approved_projects = @course.projects.none
    end 
  end

  def filtered_projects(projects)
    return projects if unrestricted_access?
    return [] unless own_supervisor?
    
    case @course.student_access.to_s
    when "own_lecturer_only"
      projects
    when "owner_only"
      projects.owned_by_user_or_groups(current_user, current_user.project_groups.where(course: @course))
    else
      []
    end
  end

  def full_access?
    @is_coordinator || current_user == @lecturer || (@is_lecturer && @course.lecturer_access)
  end

  def unrestricted_access?
    @is_student && @course.student_access.to_s == "no_restriction"
  end

  def set_empty_projects
    @my_student_projects = []
    @incoming_proposals = []
  end

  def set_empty_topics
    @approved_projects = @course.projects.none
    @own_approved_projects = @course.projects.none
    @not_own_approved_projects = @course.projects.none
  end
  
  def access?
    return true if @is_coordinator || current_user == @lecturer
    return @course.lecturer_access if @is_lecturer
    return true if @is_student
    false
  end
  
  def own_supervisor?
    return false unless @is_student
    return false unless @lecturer_enrolment
    
    user_group_ids = current_user.project_groups.where(course: @course).pluck(:id)
    
    @course.projects.student_projects_for_lecturer(@lecturer_enrolment).joins(:ownership).where(
      "(ownerships.owner_type = 'User' AND ownerships.owner_id = ?) OR 
       (ownerships.owner_type = 'ProjectGroup' AND ownerships.owner_id IN (?))",
       current_user.id, user_group_ids).exists?
  end
end