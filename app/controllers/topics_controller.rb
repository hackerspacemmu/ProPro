class TopicsController < ApplicationController
  before_action :set_course
  before_action :set_topic, only: [:show, :edit, :update, :destroy, :change_status]

  def index
    @topics = policy_scope(@course.topics)

    query = params[:query].to_s.downcase
    return unless query.present?

    @topics = @topics.select do |topic|
      latest = topic.topic_instances.order(version: :desc).first
      title = latest&.title&.downcase
      description = latest&.project_instance_fields
                          &.includes(:project_template_field)
                          &.find { |f| f.project_template_field.label.downcase.include?('description') }
                          &.value&.downcase
      title&.include?(query) || description&.include?(query)
    end
  end

  def show
    authorize @topic

    @instances = @topic.topic_instances.order(version: :asc)
    @owner = @topic.owner
    @status = @topic.current_instance&.status
    @is_coordinator = @course.enrolments.exists?(user: current_user, role: :coordinator)
    @is_student = @course.enrolments.exists?(user: current_user, role: :student)

    @members = @owner.is_a?(ProjectGroup) ? @owner.users : [@owner]
    @lecturer = User.find(params[:lecturer_id]) if params[:lecturer_id]

    @index = params[:version].present? ? params[:version].to_i : @instances.size
    @index = @instances.size if @index <= 0 || @index > @instances.size

    @current_instance = @instances[@index - 1]

    if @current_instance.nil?
      redirect_to course_path(@course), alert: 'No project instance available.'
      return
    end

    @current_fields = @current_instance.project_instance_fields
                                       .includes(:project_template_field)
                                       .order(project_template_field_id: :asc)
    @latest_version = @instances.size
    @next_fields = nil

    if @index < @instances.size
      @next_instance = @instances[@index]
      @next_fields = @next_instance.project_instance_fields
                                   .includes(:project_template_field)
                                   .order(project_template_field_id: :asc)
    end

    @comments = @current_instance.comments.order(created_at: :asc)
    @new_comment = Comment.new
    @fields = @current_fields
  end

  def new
    @template_fields = @course.project_template.project_template_fields
                              .where(applicable_to: %i[topics both])

    return if @template_fields.present?

    redirect_to course_path(@course), alert: 'Project template is missing or incomplete.'
  end

  def edit
    authorize @topic

    @instance = @topic.topic_instances.last || @topic.topic_instances.build
    @existing_values = @instance.project_instance_fields.each_with_object({}) do |f, h|
      h[f.project_template_field_id] = f.value
    end
    @template_fields = @course.project_template.project_template_fields
                              .where(applicable_to: %i[topics both])
  end

  def create
    begin
      ActiveRecord::Base.transaction do
        status = @course.require_coordinator_approval? ? :pending : :approved

        @topic = Topic.create!(course: @course, owner: current_user)

        title_value = nil
        params[:fields]&.each do |field_id, value|
          title_value = value if ProjectTemplateField.find(field_id).label.strip.downcase.include?('title')
        end

        @instance = @topic.topic_instances.create!(
          version: 1,
          title: title_value,
          created_by: current_user,
          status: status
        )

        params[:fields]&.each do |field_id, value|
          @instance.project_instance_fields.create!(
            project_template_field: ProjectTemplateField.find(field_id),
            value: value
          )
        end
      end
    rescue StandardError
      redirect_to course_path(@course), alert: 'Topic creation failed'
      return
    end

    redirect_to course_topic_path(@course, @topic), notice: 'Topic created!'
  end

  def update
    authorize @topic

    status = @course.require_coordinator_approval? ? :pending : :approved
    
    has_coordinator_comment = @topic.topic_instances.last.comments.any? do |comment|
      @course.coordinators.pluck(:id).include?(comment.user_id)
    end

    begin
      ActiveRecord::Base.transaction do
        @instance = @topic.instance_to_edit(
          created_by: current_user,
          has_coordinator_comment: has_coordinator_comment,
          status: status
        )

        raise StandardError unless params[:fields].present?

        # Set Title
        title_field_id = params[:fields].keys.first
        @instance.title = params[:fields][title_field_id] if title_field_id.present?

        # Timestamps
        @instance.last_edit_time = Time.current
        @instance.last_edit_by = current_user.id

        raise StandardError unless @instance.save

        params[:fields].each do |field_id, value|
          existing = ProjectInstanceField.find_by(
              project_template_field_id: field_id, 
              instance: @instance
            )

          if existing
            existing.update!(value: value)
          else
            @instance.project_instance_fields.create!(
                project_template_field_id: field_id, 
                value: value
              )
          end
        end
      end
    rescue StandardError
      redirect_to course_topic_path(@course, @topic), alert: 'Topic update failed'
      return
    end

    redirect_to course_topic_path(@course, @topic), notice: 'Topic updated successfully.'
  end

  def change_status
    current_instance = @topic.current_instance
    if current_instance
      current_instance.update!(
        status: params[:status],
        last_status_change_time: Time.current,
        last_status_change_by: current_user.id
      )
    end

    GeneralMailer.with(
      username: @topic.owner.username,
      email_address: @topic.owner.email_address,
      course: @course,
      topic: @topic,
      supervisor_username: Current.user.username
    ).Topic_Status_Updated.deliver_later

    redirect_to course_topic_path(@course, @topic), notice: 'Status updated.'
  end

  def destroy
    authorize @topic, :destroy?
    @topic.destroy
    redirect_to course_path(@course), notice: 'Topic deleted'
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_topic
    @topic = @course.topics.find_by(id: params[:id])
    redirect_to course_path(@course), alert: 'Topic not found.' if @topic.nil?
  end
end
