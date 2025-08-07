class ProjectsController < ApplicationController

before_action :access
before_action :check_existing_project, only: [:new, :create]

def show

  if @project.nil?
    redirect_to course_path(@course), alert: "Project not found or access denied." and return
  end

  @instances = @project.project_instances.order(version: :asc)
  @owner = @project.ownership&.owner
  @status = @project.status
  @comments = @project.comments
  @new_comment = Comment.new


  user_type = @project.ownership&.ownership_type

  if user_type == "lecturer"
    @type = "topic"
  else
    @type = "proposal"
  end

  @lecturers = @course.enrolments.where(role: [:lecturer, :coordinator]).includes(:user).map(&:user)


  if @owner.is_a?(ProjectGroup)
    @members = @owner.users  #All memebers if group project
  else
    @members = [@owner] #individual
  end


  # Determine which version to show (default: newest, i.e., array length - 1)

  if !params[:version].blank?
    @index = params[:version].to_i
  else
    @index = @instances.size
  end

  if @index <= 0 || @index > @instances.size
    @index = @instances.size
  end

  @current_instance = @instances[@index - 1]

  @fields = @current_instance.project_instance_fields.includes(:project_template_field)

  @comments = @project.comments.where(project_version_number: @index)
  @new_comment = Comment.new

end

def change_status
  if @project.supervisor == current_user
    new_status = params[:status]

    if Project.statuses.key?(new_status)
      @project.project_instances.last.update(status: new_status)

      redirect_to course_project_path(@course, @project), notice: "Status updated to #{new_status.humanize}."
    else
      redirect_to course_project_path(@course, @project), notice: "Status updated."
    end
  else
    redirect_to course_project_path(@course, @project), alert: "You are not authorized to perform this action."
  end
end


def edit
  @instance = @project.project_instances.last || @project.project_instances.build
  # Exclude lecturer-only fields 
  @template_fields = @course.project_template.project_template_fields.where.not(applicable_to: :topics)

  @existing_values = @instance.project_instance_fields.each_with_object({}) do |f, h|
    h[f.project_template_field_id] = f.value
  end
end

def update
  has_supervisor_comment = Comment.where(
    project: @project,
    project_version_number: @project.project_instances.count,
    user_id: @project.supervisor
  ).exists?

  if @project.status == "approved"
    return
  elsif @project.status == "rejected" || @project.status == "redo" || (@project.status == "pending" && has_supervisor_comment)
    version = @project.project_instances.count + 1
    @instance = @project.project_instances.build(version: version, created_by: current_user)
  else
    @instance = @project.project_instances.last
  end

  # Set title
  title_field_id = params[:fields].keys.first if params[:fields].present?
  @instance.title = params[:fields][title_field_id] if title_field_id.present?

  if @instance.save
    if params[:fields].present?
      begin
        ActiveRecord::Base.transaction do
          params[:fields].each do |field_id, value|
            existing_field = ProjectInstanceField.find_by(
              project_template_field_id: field_id,
              project_instance: @instance
            )

            if existing_field
              existing_field.update!(value: value)
            else
              @instance.project_instance_fields.create!(
                project_template_field_id: field_id,
                value: value
              )
            end
          end
        end
      rescue StandardError => e
        redirect_to course_project_path(@course, @project), alert: "Project update failed"
      end
    end

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

  @template_fields = @course.project_template.project_template_fields.where(applicable_to: [:proposals, :both])
end

#TODO: MAKE ENROLMENT POINT TO THE CORRECT SUPERVISOR
def create
  @course = Course.find(params[:course_id])
  grouped = @course.grouped?
  title_value = nil

  if grouped
    #Grouped project
    group = current_user.project_groups.find_by(course: @course)

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

    #@enrolment = Enrolment.find_or_create_by!(user: current_user, course: @course)

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

# make sure that same logic in helpers/projects_helper.rb
def access
  @course = Course.find(params[:course_id])

  @is_student = @course.enrolments.exists?(user: current_user, role: :student)

  # Build the list of projects/topics visible to the current user:
  if @course.enrolments.exists?(user: current_user, role: :coordinator)
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
      next true if project.ownership.ownership_type == "lecturer" &&
                   project.status.to_s == "approved"

      false
    end
  end

  if params[:id]
    @project = @projects.find { |p| p.id == params[:id].to_i }
    return redirect_to(course_path(@course), alert: "You are not authorized") if @project.nil?
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

  return redirect_to(course_path(@course), alert: "You are not authorized") unless authorized
end
end


