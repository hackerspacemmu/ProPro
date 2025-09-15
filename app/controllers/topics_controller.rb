class TopicsController < ApplicationController
  before_action :access_one,  only: [:index, :show, :edit, :update, :destroy, :change_status]
  before_action :set_course, only: [:new, :create]
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

    @comments = @current_instance.comments
    @new_comment = Comment.new

    @fields = @current_instance.project_instance_fields.includes(:project_template_field)
  end

  def change_status
    @is_coordinator = @course.enrolments.exists?(user: current_user, role: :coordinator)

    if @is_coordinator
      @topic.topic_instances.last.update!(status: params[:status])

      GeneralMailer.with(
        username: @topic.owner.username,
        email_address: @topic.owner.email_address,
        course: @course,
        topic: @topic,
        supervisor_username: Current.user.username
      ).Topic_Status_Updated.deliver_now

      redirect_to course_topic_path(@course, @topic), notice: "Status updated."
    else
      redirect_to course_topic_path(@course, @topic), alert: "You are not authorized to perform this action."
    end
  end

  def edit
    @instance = @topic.topic_instances.last || @topic.topic_instances.build

    @existing_values = @instance.project_instance_fields.each_with_object({}) do |f, h|
      h[f.project_template_field_id] = f.value
    end

    @template_fields = @course.project_template.project_template_fields.where(applicable_to: [:topics, :both])
  end

  def update
    has_coordinator_comment = false

    coordinator_ids = @course.coordinators.pluck(:id)

    @topic.topic_instances.last.comments.each do |comment|
      if coordinator_ids.include? comment.user_id
        has_coordinator_comment = true
        break
      end
    end

    begin
      ActiveRecord::Base.transaction do
        status = @course.require_coordinator_approval ? "pending" : "approved"

        if @topic.status == "rejected" || @topic.status == "redo" || (@topic.status == "pending" && has_coordinator_comment)
          version = @topic.topic_instances.count + 1
          @instance = @topic.topic_instances.build(version: version, created_by: current_user, status: status)
        else
          @instance = @topic.topic_instances.last
        end
        
        if !params[:fields].present?
          raise StandardError
        end

        # Set title
        title_field_id = params[:fields].keys.first if params[:fields].present?
        @instance.title = params[:fields][title_field_id] if title_field_id.present?
        
        if !@instance.save
          raise StandardError
        end

        params[:fields].each do |field_id, value|
          existing_field = ProjectInstanceField.find_by(
            project_template_field_id: field_id,
            instance: @instance
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
      redirect_to course_topic_path(@course, @topic), alert: "Project update failed"
      return
    end

    redirect_to course_topic_path(@course, @topic), notice: "Project updated successfully."
  end


  def new
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
    begin
      ActiveRecord::Base.transaction do
        status = @course.require_coordinator_approval? ? :pending : :approved

        @topic = Topic.create!(
          course: @course,
          owner: current_user
        )

        title_value = nil

        params[:fields]&.each do |field_id, value|
          template_field = ProjectTemplateField.find(field_id)
          if template_field.label.strip.downcase.include?("title")
            title_value = value
          end
        end

        @instance = @topic.topic_instances.create!(
          version: 1,
          title: title_value,
          created_by: current_user,
          status: status
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
      redirect_to course_topic_path(@course, @topic), alert: "Topic creation failed"
      return
    end

    redirect_to course_topic_path(@course, @topic), notice: "Topic created!"
  end

  def destroy
    if Current.user == @topic.owner
      @topic.destroy
      redirect_to course_path(@course), notice: "Topic deleted"
    else
      redirect_to course_topic_path(@course, @topic), alert: "You are not authorized to delete this topic."
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
      @topics = @course.topics # Coordinators see every lecturer topic (any status)

    elsif @is_lecturer
      own = @course.topics.where(owner: Current.user)
      approved = @course.topics.where(status: :approved)

      @topics = own.or(approved) # Lecturers see their own (any status) OR others' approved
    else
      @topics = @course.topics.where(status: :approved) # Students see only approved
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

  def set_course
    @course  = Course.find(params[:course_id])
  end
end
