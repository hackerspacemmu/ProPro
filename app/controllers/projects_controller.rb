class ProjectsController < ApplicationController

before_action :access

def index

end

def show

  @instances = @project.project_instances.order(version: :desc)
  @owner = @project.ownership&.owner
  @status = @project.status

  @type = @project.ownership&.ownership_type

  @members = @owner.is_a?(ProjectGroup) ? @owner.users : [@owner]

  @lecturers = @course.enrolments.where(role: :lecturer).includes(:user).map(&:user)


  if @owner.is_a?(ProjectGroup)
    @members = @owner.users  #All memebers if group project
  else
    @members = [@owner] #individual
  end


  # Determine which version to show (default: newest, i.e., index 0)
  index = params[:version].to_i
  index = 0 if index >= @instances.size || index < 0

  @current_instance = @instances[index]

  @fields = @current_instance.project_instance_fields.includes(:project_template_field)


end

def change_status

  if current_user.is_staff
    @project.update(status: Project.statuses.key(params[:status].to_i))
    redirect_to course_project_path(@course, @project), notice: "Status updated."
  else
    redirect_to course_project_path(@course, @project), alert: "You are not authorized to perform this action."
  end

end

def edit

  @instance = @project.project_instances.last || @project.project_instances.build
  
  # Exclude lecturer-only fields (applicable_to == 1)
  @template_fields = @course.project_template.project_template_fields.where.not(applicable_to: 1)


end

def update

  @instance = @project.project_instances.last

  unless @instance
    redirect_to course_project_path(@course, @project), alert: "No project instance found to update."
    return
  end

  #Sets Title 
  title_field_id = params[:fields].keys.first if params[:fields].present?
  @instance.title = params[:fields][title_field_id] if title_field_id.present?

  if params[:id] && @project.nil?
    redirect_to course_projects_path(@course), alert: "You are not authorized"
  end



  if @instance.save
    if params[:fields].present?
      params[:fields].each do |field_id, value|
        field_record = @instance.project_instance_fields.find_or_initialize_by(project_template_field_id: field_id)
        field_record.value = value
        field_record.save!
      end
    end
    redirect_to course_project_path(@course, @project), notice: "project updated successfully."
  else
    flash.now[:alert] = "Error saving project: #{@instance.errors.full_messages.join(", ")}"
    @template_fields = @course.project_template.project_template_fields
    render :edit
  end
end

private 

def access
  @courses = Current.user.courses
  @course = Course.find(params[:course_id])

  student_projects = @course.projects.select do |project|
    owner = project.ownership&.owner
    owner.is_a?(User) && @course.enrolments.exists?(user: owner, role: :student)
  end

  if @course.owner_only?

   if params[:id]
      @project = student_projects.find { |p| p.id == params[:id].to_i }
      redirect_to course_projects_path(@course), alert: "You are not authorized" if @project.nil?
    else
      @projects = student_projects.select { |p| p.ownership&.owner == current_user }
    end

  elsif @course.own_lecturer_only?

  if params[:id]
      @project = student_projects.find { |p| p.id == params[:id].to_i }
      redirect_to course_projects_path(@course), alert: "You are not authorized" if @project.nil?
    else
      if current_user.is_staff?
        @projects = student_projects  # all lecturer projects
      else
        @projects = student_projects.select { |p| p.ownership&.owner == current_user }
      end
    end

 
  elsif @course.no_restriction?
    if params[:id]
      @project = student_projects.find { |p| p.id == params[:id].to_i }
      redirect_to course_projects_path(@course), alert: "You are not authorized" if @project.nil?
    else
      @projects = student_projects
    end
  end
end
end