class LecturersController < ApplicationController
  before_action :set_course
  helper_method :access?, :own_supervisor? 
  
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
    if @lecturer_enrolment
      base_projects = @course.projects.student_projects_for_lecturer(@lecturer_enrolment)
      
      if access?
        @my_student_projects = base_projects.approved
        @incoming_proposals = base_projects.proposals
      else
        if @is_student && @course.student_access.to_s == "owner_only"
          @my_student_projects = base_projects.approved.joins(:ownership)
            .where(ownerships: { owner_type: "User", owner_id: current_user.id })
          @incoming_proposals = base_projects.proposals.joins(:ownership)
            .where(ownerships: { owner_type: "User", owner_id: current_user.id })
        else
          @my_student_projects = []
          @incoming_proposals = []
        end
      end
    else
      @my_student_projects = []
      @incoming_proposals = []
    end
  end
  
  def set_lecturer_topics
    if @lecturer_enrolment
      lecturer_owned_topics = @course.projects.lecturer_owned.where(ownerships: { owner_type: "User", owner_id:  @lecturer.id})
      
      @approved_projects = if access?
        lecturer_owned_topics
      else
        lecturer_owned_topics.where(status: :approved)
      end
      
      @own_approved_projects = lecturer_owned_topics.where(status: :approved)
      @not_own_approved_projects = lecturer_owned_topics.where(status: [:redo, :rejected, :pending])
    else
      @approved_projects = @course.projects.none
      @own_approved_projects = @course.projects.none
      @not_own_approved_projects = @course.projects.none
    end
  end
  
  def access?
    return true if @is_coordinator
    return true if current_user == @lecturer
    
    if @is_lecturer
      return @course.lecturer_access
    end
    
    if @is_student
      case @course.student_access.to_s
      when "no_restriction"
        return true
      when "own_lecturer_only"
        return own_supervisor?
      when "owner_only"
        return true 
      end
    end
    
    false
  end
  
  def own_supervisor?
    return false unless @is_student
    
    @course.projects.student_projects_for_lecturer(@lecturer_enrolment)
      .joins(:ownership)
      .where(ownerships: { owner_type: "User", owner_id: current_user.id })
      .exists?
  end
end