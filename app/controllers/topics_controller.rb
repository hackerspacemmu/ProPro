class TopicsController < ApplicationController
  include ParticipantBrowsing

  # Params that narrow a list. "all" is the selects' neutral choice and counts
  # as inactive, as does an absent/blank param.
  TOPIC_FILTER_KEYS = %w[search_query topic_filter].freeze

  before_action :set_course
  before_action :set_topic, only: %i[show edit update destroy change_status]
  # index is the Topics tab page (route-per-tab, ADR 0019): a course with
  # toggle_topics off renders the disabled empty state from the tab itself
  # rather than bouncing to Overview like every other topics action does.
  before_action :toggle_topics, except: %i[index]

  # The Topics tab — /courses/:course_id/topics. Browse-first topics directory
  # (ADR 0013), now a real route; `section=topics` htmx dispatch from
  # courses#show moved here as the HX-Request branch below.
  def index
    authorize @course, :show?

    @lecturers = @course.lecturers
    @topic_list = policy_scope(@course.topics, policy_scope_class: TopicPolicy::Scope)
    # Topics Directory data source — policy-scoped with search/filter applied
    # server-side; driving both the initial render and the htmx re-render of
    # _topics_by_supervisor_list.
    @filtered_topic_list = filtered_topic_list.to_a
    @topics_by_supervisor = topics_by_supervisor

    @topic_list_state = list_state(@topic_list, @filtered_topic_list)
    @topic_filters_active = filters_active?(TOPIC_FILTER_KEYS)

    return unless request.headers['HX-Request']

    render partial: 'courses/topics_by_supervisor_list',
           locals: {
             course: @course,
             lecturers: @lecturers,
             topics_by_supervisor: @topics_by_supervisor,
             current_user_enrolment: @current_user_enrolment,
             state: @topic_list_state,
             filters_active: @topic_filters_active
           }
    nil
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

    @compare_index = @index
    @compare_fields = @current_fields
    @compare_next_fields = @next_fields

    if @index == @instances.size && @instances.size > 1
      previous_instance = @instances[@index - 2]
      @compare_index = @index - 1
      @compare_fields = previous_instance.project_instance_fields
                                         .includes(:project_template_field)
                                         .order(project_template_field_id: :asc)
      @compare_next_fields = @current_fields
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

    topics_scope = Topic.includes(:course, topic_instances: { project_instance_fields: :project_template_field })
                        .where(course_id: Course.managed_by(current_user).select(:id))

    topics_scope = topics_scope.where(owner: current_user) unless params[:show_all_course_topics] == 'true'

    @approved_topics = topics_scope.select { |t| t.current_status == 'approved' }
                                   .sort_by(&:created_at).reverse

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
          title_value = value if ProjectTemplateField.find(field_id).is_project_title?
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
    authorize @topic, :change_status?
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
    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
  end

  def toggle_topics
    return if @course.toggle_topics

    redirect_to course_path(@course), alert: 'Topics are Disabled for this Course'
  end

  def set_topic
    @topic = @course.topics.find_by(id: params[:id])
    redirect_to course_path(@course), alert: 'Topic not found.' if @topic.nil?
  end

  # Topics Directory filters (moved from courses#show with the tab, ADR 0019).

  def search_topics(topic_list, query)
    downcased_query = query.downcase

    topic_list.select do |topic|
      title_match = topic.current_title.to_s.downcase.include?(downcased_query)
      owner_match = topic.owner_name.to_s.downcase.include?(downcased_query)

      title_match || owner_match
    end
  end

  def filtered_topic_list
    topic_list = @topic_list

    topic_list = topic_list.select { |topic| topic.owner_id == params[:topic_filter].to_i } if params[:topic_filter].present? && params[:topic_filter] != 'all'

    topic_list = search_topics(topic_list, params[:search_query]) if params[:search_query].present?

    topic_list
  end

  # [lecturer, topics] pairs for the Topics Directory, supervisor groups A→Z by
  # name. The current user's own group is pinned first (the "(You)" suffix is
  # rendered by the partial); only meaningful for users who are themselves in
  # @course.lecturers — students and coordinator-only staff get no pinned group.
  # Topics newest-first within each group.
  def topics_by_supervisor
    pairs = @course.lecturers
                   .sort_by { |lecturer| lecturer.name.to_s.downcase }
                   .map { |lecturer| [lecturer, @filtered_topic_list.select { |topic| topic.owner_id == lecturer.id }] }

    if (pinned = pairs.find { |lecturer, _topics| lecturer.id == current_user.id })
      pairs = [pinned] + pairs.reject { |lecturer, _topics| lecturer.id == current_user.id }
    end

    pairs.each { |_lecturer, topics| topics.sort_by!(&:updated_at).reverse! }
    pairs
  end
end
