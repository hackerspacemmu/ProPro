class ProjectTemplatesController < ApplicationController
  before_action :set_course
  before_action :set_project_template

  def new
    if @course.project_template
      redirect_to edit_course_project_template_path(@course)
    else
      @project_template = @course.build_project_template
    end
  end

  def create 
    return redirect_to edit_course_project_template_path(@course) if @course.project_template

    @project_template = @course.build_project_template(project_template_params)
    if @project_template.save
      redirect_to edit_course_project_template_path(@course), notice: "Template created"
    else
      render :new
    end
  end

  def update
    if @project_template.update(project_template_params)
      redirect_to edit_course_project_template_path(@course), notice: "Template updated"
    else
      render :edit
    end
  rescue
    render :edit
  end

  def edit
    @project_template = @course.project_template
  end


  private 

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_project_template
    @project_template = @course.project_template 
  end 

  def project_template_params
    params.require(:project_template).permit(
      :description,
      project_template_fields_attributes: [
        :id,
        :label,
        :hint,
        :field_type,
        :applicable_to,
        :_destroy,
        { options: [] }
      ]
    )
  end


  def access
    @course = Course.find(params[:course_id])
    
    # Check if user is coordinator first
    is_coordinator = @course.enrolments.exists?(user: current_user, role: :coordinator)
    
    # Build the list of projects/topics visible to the current user:
    if is_coordinator
      # Coordinators see everything
      @projects = @course.projects
    else
      # Non-coordinators:
      @projects = @course.projects.select do |project|
        owner = project.ownership&.owner
        # 1) Student-owned proposals (all statuses except rejected are OK)
        next true if owner.is_a?(User) &&
                     @course.enrolments.exists?(user: owner, role: :student)
        # 2) Group-owned proposals (all members are students)
        next true if owner.is_a?(ProjectGroup) &&
                     owner.users.all? { |u| @course.enrolments.exists?(user: u, role: :student) }
        # 3) Lecturer-proposed topics, but only once approved
        next true if project.ownership.lecturer? &&
                     project.status.to_s == "approved"
        false
      end
    end
    
    if params[:id]
      @project = @projects.find { |p| p.id == params[:id].to_i }
      return redirect_to(course_path(@course), alert: "You are not authorized") if @project.nil?
    end
    
    # Coordinators are always authorized - skip further checks
    return if is_coordinator
    
    # Authorization logic for non-coordinators
    authorized = false
    
    if @course.lecturer_access && @course.lecturers.exists?(user: current_user)
      authorized = true
    elsif @course.owner_only?
      authorized = @project.nil? || @project.ownership&.owner == current_user
    elsif @course.own_lecturer_only?
      authorized = @project.nil? || (
        @project.ownership&.owner == current_user ||
        @project.supervisor&.user == current_user
      )
    elsif @course.no_restriction?
      authorized = @project.nil? || (
        @course.students.exists?(user: current_user) ||
        @project.supervisor&.user == current_user
      )
    end
    
    return redirect_to(course_path(@course), alert: "You are not authorized") unless authorized
  end
end