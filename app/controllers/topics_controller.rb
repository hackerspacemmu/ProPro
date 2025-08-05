class TopicsController < ApplicationController

before_action :access_one

def index

end


def show

  @instances = @project.project_instances.order(version: :desc)
  @owner = @project.ownership&.owner
  @status = @project.status
  @comments = @project.comments
  @new_comment = Comment.new


  @type = @project.ownership&.ownership_type

  @members = @owner.is_a?(ProjectGroup) ? @owner.users : [@owner]

  @is_coordinator = @course.enrolments.exists?(user: current_user, role: :coordinator)

  if @owner.is_a?(ProjectGroup)
    @members = @owner.users  #All memebers if group project
  else
    @members = [@owner] #individual
  end


  # Determine which version to show (default: newest, i.e., index 0)
  index = params[:version].to_i
  index = 0 if index >= @instances.size || index < 0

  @current_instance = @instances[index]

  if @current_instance.nil?
    redirect_to course_path(@course), alert: "No project instance available."
    return
  end

  @fields = @current_instance.project_instance_fields.includes(:project_template_field)


end

def change_status

  @is_coordinator = @course.enrolments.exists?(user: current_user, role: :coordinator)


  if @is_coordinator
    @project.update(status: params[:status])
    redirect_to course_topic_path(@course, @project), notice: "Status updated."
  else
    redirect_to course_topic_path(@course, @project), alert: "You are not authorized to perform this action."
  end

end

def edit

  if @project.status == "pending" || (@project.status == "approved" && !@course.require_coordinator_approval)
    @instance = @project.project_instances.last || @project.project_instances.build
  elsif @project.status == "rejected"
    # Create a new version
    version = @project.project_instances.maximum(:version).to_i + 1
    @instance = @project.project_instances.build(version: version, created_by: current_user)
  else
    redirect_to course_topic_path(@course, @project), alert: "This project cannot be edited."
    return
  end

  @template_fields = @course.project_template.project_template_fields.where(applicable_to: [:topics, :both])
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
        field = @instance.project_instance_fields.find_or_initialize_by(project_template_field_id: field_id)
        field.value = value
        field.save!
      end
    end

    if @course.require_coordinator_approval
      @project.update(status: :pending) if @project.status == "approved"
    else
      @project.update(status: :pending) if @project.status == "rejected"
    end
    
    redirect_to course_topic_path(@course, @project), notice: "Project updated successfully."
  else
    flash.now[:alert] = "Error saving project: #{@instance.errors.full_messages.join(', ')}"
    @template_fields = @course.project_template.project_template_fields
    render :edit
  end
end


def new

  enrolment = Enrolment.find_by(user: current_user, course: Course.find(params[:course_id]))

  unless Current.user.is_staff
    redirect_to course_path(@course), alert: "You are not authorized"
  end

  @template_fields = @course.project_template.project_template_fields.where(applicable_to: [:topics, :both])


  if @template_fields.blank?
    redirect_to course_path(@course), alert: "Project template is missing or incomplete. Please set it up before creating a project."
    return
  end
end



def create
  enrolment = Enrolment.find_by(user: current_user, course: @course)

  # Create ownership with current_user as the owner
  @ownership = Ownership.find_or_create_by!(
    owner: enrolment.user,
    ownership_type: :lecturer
  )

  status = @course.require_coordinator_approval? ? :pending : :approved


  # Create project with valid enrolment and ownership
  @project = Project.create!(
    course: @course,
    enrolment: @course.coordinator,
    ownership: @ownership,
    status: status
  )

title_value = nil

params[:fields]&.each do |field_id, value|
  template_field = ProjectTemplateField.find(field_id)
  if template_field.label.strip.downcase.include?("title")
    title_value = value
  end
end

#creates the instance
@instance = @project.project_instances.create!(
  version: 0,
  title: title_value,
  created_by: current_user
)

# saves all fields to the instance
params[:fields]&.each do |field_id, value|
  template_field = ProjectTemplateField.find(field_id)

  @instance.project_instance_fields.create!(
    project_template_field: template_field,
    value: value
  )
end


  redirect_to course_topic_path(@course, @project), notice: "Topic created!"
end
end




private 


  def access_one
  @course = Course.find(params[:course_id])
  @courses = Current.user.courses
  @current_user_enrolment = @course.enrolments.find_by(user: Current.user)

  @is_student     = @course.enrolments.exists?(user: Current.user, role: :student)
  @is_lecturer    = @course.enrolments.exists?(user: Current.user, role: :lecturer)
  @is_coordinator = @course.enrolments.exists?(user: Current.user, role: :coordinator)

  # Only includes projects created by lecturers
  if Current.user.is_staff
  @projects = @course.projects.joins(:ownership).where(ownership: { ownership_type: :lecturer })
    else
  @projects = @course.projects.joins(:ownership).where(ownership: { ownership_type: :lecturer }, status: :approved)
  end


  @projects = @projects.select(&:approved?) if @is_student

  if params[:id]
    @project = @projects.find { |p| p.id == params[:id].to_i }
    unless @project
      redirect_to course_path(@course), alert: "You are not authorized to view this topic."
      return
    end
  end

  #Search
  query = params[:query].to_s.downcase
  if query.present?
    @projects = @projects.select do |project|
      latest = project.project_instances.order(version: :desc).first
      title = latest&.title&.downcase
      description = latest&.project_instance_fields
        &.includes(:project_template_field)
        &.find { |f| f.project_template_field.label.downcase.include?("description") }
        &.value&.downcase

      title&.include?(query) || description&.include?(query)
    end
  end
end
