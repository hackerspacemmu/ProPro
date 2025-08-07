class TopicsController < ApplicationController

before_action :access_one,  only: [:index, :show, :edit, :update, :destroy, :change_status]
before_action :set_course_and_enrolment, only: [:new, :create]
def index

end


def show

  @instances = @project.project_instances.order(version: :asc)
  @owner = @project.ownership&.owner
  @status = @project.status


  @members = @owner.is_a?(ProjectGroup) ? @owner.users : [@owner]

  @is_coordinator = @course.enrolments.exists?(user: current_user, role: :coordinator)

  if @owner.is_a?(ProjectGroup)
    @members = @owner.users  #All memebers if group project
  else
    @members = [@owner] #individual
  end


  if !params[:version].blank?
    @index = params[:version].to_i
  else
    @index = @instances.size
  end

  if @index <= 0 || @index > @instances.size
    @index = @instances.size
  end

  @current_instance = @instances[@index - 1]

  if @current_instance.nil?
    redirect_to course_path(@course), alert: "No project instance available."
    return
  end

  @comments = @project.comments.where(project_version_number: @index)
  @new_comment = Comment.new

  @fields = @current_instance.project_instance_fields.includes(:project_template_field)

  user_type = @project.ownership&.ownership_type

  if user_type == "lecturer"
    @type = "topic"
  else
    @type = "proposal"
  end
end

def change_status

  @is_coordinator = @course.enrolments.exists?(user: current_user, role: :coordinator)


  if @is_coordinator
    @project.update(status: params[:status])

    Comment.create!(
      user: Current.user,
      project: @project,
      text: "Updated status to #{new_status.capitalize}",
      project_version_number: @project.project_instances.count,
      deletable: false
    )

    redirect_to course_topic_path(@course, @project), notice: "Status updated."
  else
    redirect_to course_topic_path(@course, @project), alert: "You are not authorized to perform this action."
  end

end

def edit
    has_coordinator_comment = Comment.where(
      project: @project,
      project_version_number: @project.project_instances.count,
      user_id: @project.supervisor
    ).exists?


  if @project.status == "pending" || (@project.status == "approved" && !@course.require_coordinator_approval)
    @instance = @project.project_instances.last || @project.project_instances.build

    @existing_values = @instance.project_instance_fields.each_with_object({}) do |f, h|
      h[f.project_template_field_id] = f.value
    end
  elsif @project.status == "rejected" || @project.status == "redo" || has_coordinator_comment

    # Create a new version
    version = @project.project_instances.maximum(:version).to_i + 1
    @instance = @project.project_instances.build(version: version, created_by: current_user)
    
    latest_instance = @project.project_instances.order(version: :desc).first
    if latest_instance
      @existing_values = latest_instance.project_instance_fields.each_with_object({}) do |f, h|
        h[f.project_template_field_id] = f.value
      end
    else
      {}
    end
  else
    redirect_to course_topic_path(@course, @project), alert: "This project cannot be edited."
    return
  end
  @template_fields = @course.project_template.project_template_fields.where(applicable_to: [:topics, :both])
end

def update
  has_coordinator_comment = Comment.where(
    project: @project,
    project_version_number: @project.project_instances.count,
    user_id: @project.supervisor
  ).exists?

  if @project.status == "rejected" || @project.status == "redo" || has_coordinator_comment
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
      @project.update(status: :pending) if @project.status == "pending"
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

def destroy
  allowed = if @project.ownership.is_a?(ProjectGroup)
              @project.ownership.users
            else
              [ @project.ownership.owner ]
            end

  if allowed.include?(current_user)
    @project.destroy
    redirect_to course_path(@course), notice: "Topic deleted"
  else
    redirect_to course_topic_path(@course, @project), alert: "You are not authorized to delete this topic."
  end
end


private 


def access_one
  @course                 = Course.find(params[:course_id])
  @current_user_enrolment = @course.enrolments.find_by(user: current_user)
  @is_coordinator         = @current_user_enrolment&.coordinator?
  @is_lecturer            = @current_user_enrolment&.lecturer?
  @is_student             = @current_user_enrolment&.student?

  lt = Ownership.ownership_types[:lecturer]


  if action_name == 'index'
    # FOR TOPICS/INDEX
    @projects = @course.projects
                       .joins(:ownership)
                       .where(ownerships: { ownership_type: lt }, status: :approved)
    return
  end

  # FOR COURSES/SHOW

  if @is_coordinator
    # Coordinators see every lecturer topic (any status)
    @projects = @course.projects
                       .joins(:ownership)
                       .where(ownerships: { ownership_type: lt })

  elsif @is_lecturer
    # Lecturers see their own (any status) OR others' approved
    own = @course.projects
                 .joins(:ownership)
                 .where(ownerships: {
                   owner_type:     "User",
                   owner_id:       current_user.id,
                   ownership_type: lt
                 })

    approved = @course.projects
                      .joins(:ownership)
                      .where(ownerships: { ownership_type: lt },
                             status:     :approved)

    @projects = own.or(approved)

  else
    # Students see only approved
    @projects = @course.projects
                       .joins(:ownership)
                       .where(ownerships: { ownership_type: lt }, status: :approved)

  end

  @project = @projects.find_by(id: params[:id])
  unless @project
    redirect_to course_path(@course), alert: "You are not authorized to view this topic."
    return
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

 def set_course_and_enrolment
   @course  = Course.find(params[:course_id])
   @current_user_enrolment = @course.enrolments.find_by(user: current_user)
 end
end
