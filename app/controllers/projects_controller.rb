class ProjectsController < ApplicationController

before_action :access

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

  @preselected_lecturer_id = params[:lecturer_id] || params[:supervisor_id]
  @lecturer_options = Enrolment.where(course: @course, role: :lecturer).includes(:user)

  # Optionally preselect topic or own proposal
  @selected_topic_id = params[:topic_id].presence&.to_i
  @selected_own_proposal_lecturer_id = nil
  if params[:own_proposal_lecturer_id].present?
    @selected_own_proposal_lecturer_id = params[:own_proposal_lecturer_id].to_i
    @selected_topic_id = nil
  end
end

def update
  based_on_topic_param = params[:based_on_topic]
  has_supervisor_comment = Comment.where(
    project: @project,
    project_version_number: @project.project_instances.count,
    user_id: @project.supervisor
  ).exists?

  if @project.status == "approved"
    return
  elsif @project.status == "rejected" || @project.status == "redo" || (@project.status == "pending" && has_supervisor_comment)
    version = @project.project_instances.count + 1
    @instance = @project.project_instances.build(version: version, created_by: current_user, enrolment: @project.supervisor)
  else
    @instance = @project.project_instances.last
  end

  # Set title
  title_field_id = params[:fields].keys.first if params[:fields].present?
  @instance.title = params[:fields][title_field_id] if title_field_id.present?

  if params[:supervisor_id].present?
    supervisor_enrolment = Enrolment.find_by(user_id: params[:supervisor_id], course_id: @course.id, role: :lecturer)
    if supervisor_enrolment
      @project.enrolment = supervisor_enrolment
      @project.save!
    else
      flash[:alert] = "Supervisor not found or invalid."
      redirect_to course_project_path(@course, @project) and return
    end
  end

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
    @current_instance = @project.project_instances.last
    topic_response = TopicResponses.find_by(
      project_instance_id: @current_instance
    )
    topic = Project.find(params[:topic_id])

    if !topic
      return
    end

    if topic_response
      topic_response.update!(project: topic)
    else
      TopicResponse.create!(project: topic, project_instance: @current_instance)
    end
    redirect_to course_project_path(@course, @project), notice: "Project updated successfully."
  else
    flash.now[:alert] = "Error saving project: #{@instance.errors.full_messages.join(', ')}"
    @template_fields = @course.project_template.project_template_fields
    render :edit
  end

  if based_on_topic_param.present?
  if based_on_topic_param.start_with?("own_proposal_")
    # Extract lecturer ID from value
    lecturer_id = based_on_topic_param.split("_").last.to_i

    # Find lecturer enrolment for course
    supervisor_enrolment = Enrolment.find_by(user_id: lecturer_id, course_id: @course.id, role: :lecturer)

    if supervisor_enrolment
      @project.enrolment = supervisor_enrolment
      @project.save!
    else
      flash[:alert] = "Selected supervisor not found or invalid."
      redirect_to course_project_path(@course, @project) and return
    end

  else
    # Treat as topic_id
    topic_id = based_on_topic_param.to_i
    topic = Project.find_by(id: topic_id)

    if topic
      # Set supervisor enrolment to the owner of the topic 
      topic_owner = topic.ownership&.owner
      if topic_owner.is_a?(User)
        supervisor_enrolment = Enrolment.find_by(user_id: topic_owner.id, course_id: @course.id, role: :lecturer)
        if supervisor_enrolment
          @project.enrolment = supervisor_enrolment
          @project.save!
        else
          flash[:alert] = "Supervisor from topic owner not found."
          redirect_to course_project_path(@course, @project) and return
        end
      end
    else
      flash[:alert] = "Selected topic not found."
      redirect_to course_project_path(@course, @project) and return
    end
  end
end

end

def new
  unless @is_student
    redirect_to course_path(@course), alert: "You are not authorized"
    return
  end

  has_project = @course.projects
    .joins(:ownership)
    .where(ownerships: { owner: current_user, ownership_type: :student })
    .exists?

  #if has_project
    #redirect_to course_path(@course), alert: "You already have a project in this course."
    #return
  #end

  enrolment = Enrolment.find_by(user: current_user, course: @course)
  if enrolment && Project.exists?(enrolment: enrolment)
    redirect_to course_path(@course), alert: "You already have a project."
    return
  end

  @template_fields = @course.project_template.project_template_fields.where(applicable_to: [:proposals, :both])
  @lecturer_options = Enrolment.where(course: @course, role: :lecturer)
                            .includes(:user)
                            .map { |e| [e.user.username, e.user.id] }

if params[:topic_id].present?
  topic = Project.find(params[:topic_id])
  approved_instance = topic.project_instances.where(status: :approved).order(version: :asc).first
  @based_on_topic_name = approved_instance&.title || "Unknown Topic"
  @based_on_topic_supervisor_id = topic.ownership&.owner&.id
  @based_on_topic_id = topic.id 
  @based_on_topic = topic

  @preselected_lecturer_id = @based_on_topic_supervisor_id if @based_on_topic_supervisor_id.present?
  @lock_supervisor = true
  @lock_topic = true
elsif params[:lecturer_id].present?
  @based_on_topic_name = nil
  @based_on_topic_supervisor_id = nil
  @preselected_lecturer_id = params[:lecturer_id]
  @lock_supervisor = true   
  @lock_topic = true
else
  @based_on_topic_name = nil
  @based_on_topic_supervisor_id = nil
  @preselected_lecturer_id = nil
  @lock_supervisor = false    # LOCK supervisor dropdown otherwise
  @lock_topic = true
end

  
end

def create
  @course = Course.find(params[:course_id])
  grouped = @course.grouped?
  title_value = nil

  if grouped
    group = current_user.project_groups.find_by(course: @course)
    unless group
      redirect_to course_path(@course), alert: "You're not part of a project group." and return
    end

    if Project.joins(:ownership).where(ownerships: { owner: group, ownership_type: :project_group }).exists?
      redirect_to course_path(@course), alert: "Your group already has a project." and return
    end

    @ownership = Ownership.create!(owner: group, ownership_type: :project_group)
  else
    @enrolment = Enrolment.find_by(user: current_user, course: @course)
    if Project.exists?(enrolment: @enrolment)
      redirect_to course_path(@course), alert: "You already have a project for this course." and return
    end

    #@enrolment ||= Enrolment.create!(user: current_user, course: @course, role: :student)
    @ownership = Ownership.create!(owner: current_user, ownership_type: :student)
  end

  # Supervisor selection
  supervisor_id = params[:supervisor_id]
  supervisor_enrolment = Enrolment.find_by(user_id: supervisor_id, course_id: @course.id, role: :lecturer)

  if supervisor_enrolment.nil?
    redirect_to course_path(@course), alert: "Supervisor not found." and return
  end

  # Create project, supervised via enrolment
  @project = Project.create!(
    course: @course,
    enrolment: supervisor_enrolment,  # this links to the lecturer
    ownership: @ownership
  )

  # Get title
  params[:fields]&.each do |field_id, value|
    if ProjectTemplateField.find(field_id).label.strip.downcase.include?("title")
      title_value = value
    end
  end

  @instance = @project.project_instances.create!(
    version: 1,
    title: title_value,
    created_by: current_user, # TODO: point to lecturer enrolment,
    enrolment: supervisor_enrolment
  )
  Rails.logger.info "nigger #{@based_on_topic.inspect}"

  TopicResponses.create!(
    project: @based_on_topic,
    project_instance_id: @instance.id
  )

  #  Save fields
  params[:fields]&.each do |field_id, value|
    @instance.project_instance_fields.create!(
      project_template_field_id: field_id,
      value: value
    )
  end

  redirect_to course_projects_path(@course), notice: "Project created!"
end


private

def project_params
  params.require(:project).permit(:supervisor_id)
end

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

  @lecturers = User.joins(:enrolments)
                   .where(enrolments: { course_id: @course.id, role: :lecturer })
                   .distinct

  return redirect_to(course_path(@course), alert: "You are not authorized") unless authorized
end
end
