class ProjectsController < ApplicationController

before_action :access
before_action :check_existing_project, only: [:new, :create]

def show

  if @project.nil?
    redirect_to course_path(@course), alert: "Project not found or access denied." and return
  end

  @instances = @project.project_instances.order(version: :desc)
  @owner = @project.ownership&.owner
  @status = @project.status

  @type = @project.ownership&.ownership_type

  @lecturers = @course.enrolments.where(role: [:lecturer, :coordinator]).includes(:user).map(&:user)


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

  @comments = @project.comments
  @new_comment = Comment.new

end

def change_status

  if @project.supervisor == current_user 
    @project.update(status: Project.statuses.key(params[:status].to_i))
    redirect_to course_project_path(@course, @project), notice: "Status updated."
  else
    redirect_to course_project_path(@course, @project), alert: "You are not authorized to perform this action."
  end

end

def edit

  if @project.status == "pending"
    @instance = @project.project_instances.last || @project.project_instances.build
  elsif @project.status == "rejected"
    # Create a new version
    version = @project.project_instances.maximum(:version).to_i + 1
    @instance = @project.project_instances.build(version: version, created_by: current_user)
  else
    redirect_to course_project_path(@course, @project), alert: "This project cannot be edited."
    return
  end

  # Exclude lecturer-only fields (optional)
  @template_fields = @course.project_template.project_template_fields.where.not(applicable_to: :topics)
end

def update
  if @project.status == "rejected"
    version = @project.project_instances.maximum(:version).to_i + 1
    @instance = @project.project_instances.build(version: version, created_by: current_user)
  else
    @instance = @project.project_instances.last
  end

  # Set title
  title_field_id = params[:fields].keys.first if params[:fields].present?
  @instance.title = params[:fields][title_field_id] if title_field_id.present?

  if @instance.save
    if params[:fields].present?
      params[:fields].each do |field_id, value|
        @instance.project_instance_fields.create!(
          project_template_field_id: field_id,
          value: value
        )
      end
    end

    @project.update(status: :pending) if @project.status == "rejected"

    redirect_to course_project_path(@course, @project), notice: "Project updated successfully."
  else
    flash.now[:alert] = "Error saving project: #{@instance.errors.full_messages.join(', ')}"
    @template_fields = @course.project_template.project_template_fields
    render :edit
  end
end

def new
  unless @is_student
  redirect_to course_path(@course), alert: "You are not authorized"
  return
end

enrolment = Enrolment.find_by(user: current_user, course: @course)
if enrolment && Project.exists?(enrolment: enrolment)
  redirect_to course_path(@course), alert: "You already have a project."
  return
end

@template_fields = @course.project_template.project_template_fields.where.not(applicable_to: :proposals)

  

end


def create
  @course = Course.find(params[:course_id])
  grouped = @course.grouped?
  title_value = nil

  if grouped
    #Grouped project
    group = current_user.project_groups.find_by(course_id: @course.id)

    unless group
      redirect_to course_path(@course), alert: "You're not part of a project group." and return
    end

    existing_project = Project.joins(:ownership)
                              .where(ownerships: { owner: group, ownership_type: :project_group })
                              .first

    if existing_project
      redirect_to course_path(@course), alert: "Your group already has a project." and return
    end

    @ownership = Ownership.create!(
      owner: group,
      ownership_type: :project_group
    )

    @enrolment = Enrolment.find_or_create_by!(user: current_user, course: @course)

  else
    # Individual student project 
    @enrolment = Enrolment.find_by(user: current_user, course: @course)
    existing_project = Project.find_by(enrolment: @enrolment)

    if existing_project
      redirect_to course_path(@course), alert: "You already have a project for this course." and return
    end

    @enrolment = Enrolment.find_or_create_by!(
      user: current_user,
      course: @course,
      role: @enrolment&.role || :student
    )

    @ownership = Ownership.create!(
      owner: current_user,
      ownership_type: :student
    )
  end

  # Create project
  @project = Project.create!(
    course: @course,
    enrolment: @enrolment,
    ownership: @ownership
  )


params[:fields]&.each do |field_id, value|
  template_field = ProjectTemplateField.find(field_id)
  if template_field.label.strip.downcase.include?("title")
    title_value = value
  end
end

#Create Instance
@instance = @project.project_instances.create!(
  version: 0,
  title: title_value,
  created_by: current_user
)

# Saves all fields to the instance
params[:fields]&.each do |field_id, value|
  template_field = ProjectTemplateField.find(field_id)

  @instance.project_instance_fields.create!(
    project_template_field: template_field,
    value: value
  )
end


  redirect_to course_topics_path(@course), notice: "Project created!"
end

def check_existing_project
  @course = Course.find(params[:course_id])
  enrolment = Enrolment.find_by(user: current_user, course: @course)

  if enrolment && Project.exists?(enrolment: enrolment)
    redirect_to course_path(@course), alert: "You have already created a project for this course."
  end
end



private 

def access
  @course = Course.find(params[:course_id])

  # coordinators see every project
  if @course.enrolments.exists?(user: current_user, role: :coordinator)
    @projects = @course.projects
  else
    @projects = @course.projects.select do |project|
      owner = project.ownership&.owner
      if owner.is_a?(User)
        @course.enrolments.exists?(user: owner, role: :student)
      elsif owner.is_a?(ProjectGroup)
        owner.users.all? { |u| @course.enrolments.exists?(user: u, role: :student) }
      else
        false
      end
    end
  end

  if params[:id]
    @project = @projects.find { |p| p.id == params[:id].to_i }
    return redirect_to(course_projects_path(@course), alert: "You are not authorized") if @project.nil?
  end

  authorized = false

  if @course.enrolments.exists?(user: current_user, role: :coordinator)
    authorized = true

  elsif @course.lecturer_access && @course.lecturers.exists?(user: current_user)
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

  return redirect_to(course_projects_path(@course), alert: "You are not authorized") unless authorized
end
end

