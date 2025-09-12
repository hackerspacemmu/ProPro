class TopicsController < ApplicationController
  before_action :access_one,  only: [:index, :show, :edit, :update, :destroy, :change_status]
  before_action :set_course_and_enrolment, only: [:new, :create]
  def index
  end

  def show
    @instances = @topic.topic_instances.order(version: :asc)
    @owner = @topic.owner
    @status = @topic.status

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

    @comments = @topic.comments.where(project_version_number: @index)
    @new_comment = Comment.new

    @fields = @current_instance.project_instance_fields.includes(:project_template_field)

    user_type = @topic.ownership_type

    if user_type == "lecturer"
      @type = "topic"
    else
      @type = "proposal"
    end
  end

  def change_status
    @is_coordinator = @course.enrolments.exists?(user: current_user, role: :coordinator)

    if @is_coordinator && Project.statuses.key?(params[:status])
      @project.project_instances.last.update(status: params[:status])


      GeneralMailer.with(
        username: @project.owner.username,
        email_address: @project.owner.email_address,
        course: @course,
        project: @project,
        supervisor_username: Current.user.username
      ).Status_Updated.deliver_now

      redirect_to course_topic_path(@course, @project), notice: "Status updated."
    else
      redirect_to course_topic_path(@course, @project), alert: "You are not authorized to perform this action."
    end
  end

  def edit
    @instance = @project.project_instances.last || @project.project_instances.build

    if @instance
      @existing_values = @instance.project_instance_fields.each_with_object({}) do |f, h|
        h[f.project_template_field_id] = f.value
      end
    else
      {}
    end
    @template_fields = @course.project_template.project_template_fields.where(applicable_to: [:topics, :both])
  end

  def update
    has_coordinator_comment = Comment.where(
      project: @project,
      project_version_number: @project.project_instances.count,
      user_id: @project.supervisor
    ).exists?

    status = @course.require_coordinator_approval ? "pending" : "approved"
    if @project.status == "rejected" || @project.status == "redo" || (@project.status == "pending" && has_coordinator_comment)
      version = @project.project_instances.count + 1
      @instance = @project.project_instances.build(version: version, created_by: current_user, status: status, enrolment: @project.enrolment)
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
    begin
      ActiveRecord::Base.transaction do
        # Create ownership with current_user as the owner
        status = @course.require_coordinator_approval? ? :pending : :approved

        # Create project with valid enrolment and ownership
        @project = Project.create!(
          course: @course,
          enrolment: @course.coordinator, #TODO: multiple coordinators
          owner: current_user,
          ownership_type: :lecturer
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
          version: 1,
          title: title_value,
          created_by: current_user,
          status: status,
          enrolment: @course.coordinator
        )

        # saves all fields to the instance
        params[:fields]&.each do |field_id, value|
          template_field = ProjectTemplateField.find(field_id)

          @instance.project_instance_fields.create!(
            project_template_field: template_field,
            value: value
          )
        end
      end
    rescue StandardError => e
      redirect_to course_topic_path(@course, @project), alert: "Topic creation failed"
    end

    redirect_to course_topic_path(@course, @project), notice: "Topic created!"
  end

  def destroy
    if Current.user == @project.owner
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

    if action_name == 'index'
      # FOR TOPICS/INDEX
      @topics = @course.topics.where(status: :approved)
      return
    end

    # FOR COURSES/SHOW

    if @is_coordinator
      # Coordinators see every lecturer topic (any status)
      @topics = @course.topics

    elsif @is_lecturer
      # Lecturers see their own (any status) OR others' approved
      own = @course.topics.where(
                     owner_type:     "User",
                     owner_id:       current_user.id,
                   )
      approved = @course.topics.where(status: :approved)

      @topics = own.or(approved)
    else
      # Students see only approved
      @topics = @course.topics.where(status: :approved)

    end

    @topic = @topics.find_by(id: params[:id])
    unless @topic
      redirect_to course_path(@course), alert: "You are not authorized to view this topic."
      return
    end

    #Search
    query = params[:query].to_s.downcase
    if query.present?
      @topics = @topics.select do |topic|
        latest = topic.topic_instances.order(version: :desc).first
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
