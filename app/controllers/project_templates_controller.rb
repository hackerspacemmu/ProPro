class ProjectTemplatesController < ApplicationController
before_action :set_course
before_action :set_project_template

  def new
    if @course.project_template
      @project_template = @course.project_template 
    else
      @project_template = @course.build_project_template
      @project_template.project_template_fields.build(
        label: "Project Title",
        field_type: "shorttext",
        applicable_to: "both"
      )
    end
  end

  def create 
    @project_template = @course.build_project_template(project_template_params)
    if @project_template.save
      redirect_to edit_course_project_template_path(@course)
    end 
  end

  def update
    safe_params = filter_undeletable_fields(project_template_params)

    if @project_template.update(safe_params)
      redirect_to edit_course_project_template_path(@course), notice: 'Template updated successfully.'
    else
      render :edit
    end
  end

  def edit
    @project_template = @course.project_template

    if @project_template.project_template_fields.empty?
      @project_template.project_template_fields.build(
        label: "Project Title",
        field_type: "shorttext",
        applicable_to: "both"
      )
    end
  end
  

  def new_field
    @index = params[:index].to_i
    render partial: 'project_templates/new_field', locals: { index: @index}
  end

  def new_option
    render partial: "project_templates/option_row_#{params[:field_type]}",
           locals: {field_index:  params[:field_index].to_i, option_index: params[:option_index].to_i, option_value: ''  }
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

  def filter_undeletable_fields(params)
    if params[:project_template_fields_attributes]
      params[:project_template_fields_attributes].each do |key, field_attrs|
        if field_attrs[:_destroy] == 'true' && field_attrs[:id].present?
          field = ProjectTemplateField.find_by(id: field_attrs[:id])
          if field && field.project_instance_fields.exists?
            field_attrs[:_destroy] = 'false'
            flash[:alert] = "Some fields could not be deleted because they're being used in existing projects."
          end
        end
      end
    end
    params
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