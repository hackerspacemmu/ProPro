class TopicsController < ApplicationController
  before_action :set_course
  before_action :set_topic, only: %i[show edit update destroy change_status]
  before_action :toggle_topics

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

    @project = if @course.grouped?
                 group = current_user.project_groups.find_by(course: @course)
                 @course.projects.find_by(owner: group) if group
               else
                 @course.projects.find_by(owner: current_user)
               end

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
    @current_version = @index
    @next_fields = nil

    if @index < @instances.size
      @next_instance = @instances[@index]
      @next_fields = @next_instance.project_instance_fields
                                   .includes(:project_template_field)
                                   .order(project_template_field_id: :asc)
    end

    @comments = @topic.comments.order(created_at: :asc)
    @new_comment = Comment.new
    @fields = @current_fields
  end

  def new
    @template_fields = @course.project_template.project_template_fields
                              .where(applicable_to: %i[topics both])

    if params[:source_topic_id].present?
      @source_topic = Topic.find(params[:source_topic_id])
      return render partial: 'copy_topic_details', layout: false, locals: { source: @source_topic, target: @course }
    end

    if params[:show_all_course_topics] == 'true'
      coordinator_course_ids = current_user.enrolments.where(role: :coordinator).pluck(:course_id)

      topics_scope = Topic.includes(:course, topic_instances: { project_instance_fields: :project_template_field })

      @approved_topics = topics_scope.select do |t|
        next false unless t.current_status == 'approved'

        owned_by_me = t.owner_type == 'User' && t.owner_id == current_user.id
        coordinates_course = coordinator_course_ids.include?(t.course_id)

        owned_by_me || coordinates_course
      end.sort_by(&:created_at).reverse
    else
      @approved_topics = Topic.includes(:course, topic_instances: { project_instance_fields: :project_template_field })
                              .where(
                                owner_type: 'User',
                                owner_id: current_user.id
                              )
                              .select { |t| t.current_status == 'approved' }
                              .sort_by(&:created_at).reverse
    end

    return render partial: 'copy_topic_overlay' if turbo_frame_request? && turbo_frame_request_id == 'overlay_content'

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

        source_id = params[:source_topic_id].presence

        status = :approved if status == :pending && source_id && @course.auto_approve_copied_topics_without_changes? && topic_unchanged_from_source?(source_id, params[:fields])

        @topic = Topic.create!(
          course: @course,
          owner: current_user,
          source_topic_id: source_id
        )

        title_value = nil
        params[:fields]&.each do |field_id, value|
          title_value = value if ProjectTemplateField.find(field_id).is_project_title?
        end

        @instance = @topic.topic_instances.create!(
          version: 1,
          title: title_value,
          created_by: current_user,
          status: status
        )

        params[:fields]&.each do |field_id, value|
          source_field_id = params.dig(:source_fields, field_id.to_s).presence

          @instance.project_instance_fields.create!(
            project_template_field: ProjectTemplateField.find(field_id),
            value: value,
            source_field_id: source_field_id
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
      name: @topic.owner.name,
      email_address: @topic.owner.email_address,
      course: @course,
      topic: @topic,
      supervisor_name: Current.user.name
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

  def toggle_topics
    return if @course.toggle_topics

    redirect_to course_path(@course), alert: 'Topics are Disabled for this Course'
  end

  def set_topic
    @topic = @course.topics.find_by(id: params[:id])
    redirect_to course_path(@course), alert: 'Topic not found.' if @topic.nil?
  end

  def topic_unchanged_from_source?(source_id, submitted_fields)
    return false if submitted_fields.blank?

    source_topic = Topic.find_by(id: source_id)
    return false unless source_topic&.current_instance

    source_fields_by_label = source_topic.current_instance.project_instance_fields
                                         .includes(:project_template_field)
                                         .each_with_object({}) do |field, hash|
      label = field.project_template_field.label.to_s.downcase.strip
      hash[label] = field.value.to_s.strip
    end

    raw_submitted = submitted_fields.to_unsafe_h

    raw_submitted.all? do |field_id, value|
      target_field = ProjectTemplateField.find_by(id: field_id)
      return false unless target_field

      target_label = target_field.label.to_s.downcase.strip
      source_value = source_fields_by_label[target_label]

      value.to_s.strip == source_value
    end
  end
end
