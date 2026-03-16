class ProjectsController < ApplicationController
  before_action :set_course
  before_action :set_project, only: %i[show edit update change_status]

  def show
    authorize @project || Project.new(course: @course)

    @instances = @project.project_instances.order(version: :asc)
    @owner = @project.owner
    @status = @project.status

    @lecturers = @course.lecturers

    @members = if @owner.is_a?(ProjectGroup)
                 @owner.users # all memebers if group project
               else
                 [@owner] # individual
               end

    # Determine which version to show (default: newest, i.e., array length - 1)
    @index = if params[:version].present?
               params[:version].to_i
             else
               @instances.size
             end

    @index = @instances.size if @index <= 0 || @index > @instances.size

    @current_instance = @instances[@index - 1]
    @current_version = @index
    @latest_version = @instances.size

    @current_fields = @current_instance.project_instance_fields.includes(:project_template_field).order(project_template_field_id: :asc)
    @next_fields = nil

    if @index < @instances.size
      @next_instance = @instances[@index]
      @next_fields = @next_instance.project_instance_fields.includes(:project_template_field).order(project_template_field_id: :asc)
    end

    @comments = @current_instance.comments.order(created_at: :asc)
    @new_comment = Comment.new(user: current_user, location: @current_instance)

    return unless @course.use_progress_updates

    @progress = @project.progress_updates.order(date: :desc)
    @weeks = @course.number_of_updates
  end

  def change_status
    authorize @project, :change_status?

    new_status = params[:status]
    @project.project_instances.last.update!(
      status: new_status,
      last_status_change_time: Time.current,
      last_status_change_by: current_user.id
    )

    GeneralMailer.with(
      course: @course,
      project: @project,
      supervisor_username: Current.user.username
    ).Project_Status_Updated.deliver_later

    redirect_to course_project_path(@course, @project), notice: "Status updated to #{new_status.humanize}."
  end

  def new
    has_project = if @course.grouped?
                    Current.user.group_projects.find_by(course: @course).present?
                  else
                    Current.user.solo_projects.find_by(course: @course).present?
                  end

    if has_project
      redirect_to course_path(@course), alert: 'You already have a project in this course.'
      return
    end

    @template_fields = @course.project_template.project_template_fields.where(applicable_to: %i[proposals both])

    @lecturer_options = Enrolment.where(course: @course, role: :lecturer).includes(:user)

    @field_values = {}

    # Optionally preselect topic or own proposal
    topic_id = params[:topic_id].presence || params[:based_on_topic]

    return unless topic_id.present?

    if topic_id.to_s.start_with?('own_proposal_')
      @selected_topic_id = topic_id
    elsif @course.topics.exists?(id: topic_id)
      @selected_topic_id = topic_id
    end
  end

  def edit
    authorize @project || Project.new(course: @course)

    @instance = @project.project_instances.last || @project.project_instances.build
    # Exclude lecturer-only fields
    @template_fields = @course.project_template.project_template_fields.where.not(applicable_to: :topics)

    @existing_values = @instance.project_instance_fields.each_with_object({}) do |f, h|
      h[f.project_template_field_id] = f.value
    end

    @lecturer_options = Enrolment.where(course: @course, role: :lecturer).includes(:user)

    # Optionally preselect topic or own proposal
    if @instance.source_topic_id.nil?
      @selected_own_proposal_lecturer_id = @instance.enrolment_id
    else
      @selected_topic_id = @instance.source_topic_id
    end
  end

  def create
    authorize Project.new(course: @course), :create?

    @course = Course.find(params[:course_id])
    begin
      ActiveRecord::Base.transaction do
        if @course.grouped?
          group = current_user.project_groups.find_by(course: @course)

          raise StandardError, "You're not part of a project group." unless group

          raise StandardError, 'Your group already has a project' if group.project
        else
          has_project = Current.user.solo_projects.find_by(course: @course)

          raise StandardError, 'You already have a project' if has_project
        end

        raise StandardError, 'Please choose a lecturer and topic' if params[:based_on_topic].blank?

        if params[:based_on_topic].start_with?('own_proposal_')
          # Extract lecturer ID from value
          lecturer_id = params[:based_on_topic].split('_').last.to_i

          # Find lecturer enrolment for course
          supervisor_enrolment = Enrolment.find_by(user_id: lecturer_id, course_id: @course.id, role: :lecturer)

          raise StandardError unless supervisor_enrolment
        else
          # Treat as topic_id
          topic = Topic.find_by(id: params[:based_on_topic], course: @course)

          raise StandardError unless topic

          # Set supervisor enrolment to the owner of the topic (assuming you want this)
          topic_owner = topic&.owner
          raise StandardError unless topic_owner.is_a?(User)

          supervisor_enrolment = Enrolment.find_by(user_id: topic_owner.id, course_id: @course.id, role: :lecturer)

          raise StandardError unless supervisor_enrolment
        end

        @project = Project.create!(
          course: @course,
          owner: @course.grouped? ? group : current_user,
          enrolment: supervisor_enrolment
        )

        # Get title
        title_value = nil
        params[:fields]&.each do |field_id, value|
          title_value = value if ProjectTemplateField.find(field_id).label.strip.downcase.include?('title')
        end

        @instance = @project.project_instances.create!(
          version: 1,
          title: title_value,
          created_by: current_user,
          enrolment: supervisor_enrolment,
          source_topic: topic || nil,
          last_edit_time: Time.current,
          last_edit_by: current_user.id
        )

        #  Save fields
        params[:fields]&.each do |field_id, value|
          @instance.project_instance_fields.create!(
            project_template_field_id: field_id,
            value: value
          )
        end
      end
    rescue StandardError => e
      redirect_to course_path(@course), alert: e.message
      return
    end

    GeneralMailer.with(
      email_address: @project.supervisor.email_address,
      supervisor_username: @project.supervisor.username,
      owner_name: @course.grouped? ? @project.owner.group_name : @project.owner.username,
      course: @course,
      project: @project
    ).New_Student_Submission.deliver_later

    redirect_to course_project_path(@course, @project), notice: 'Project created!'
  end

  def update
    authorize @project || Project.new(course: @course)

    has_supervisor_comment = false
    @project.project_instances.last.comments.each do |comment|
      if comment.user_id == @project.supervisor.id
        has_supervisor_comment = true
        break
      end
    end

    previous_supervisor_id = @project.supervisor.id
    new_instance_created = false

    begin
      ActiveRecord::Base.transaction do
        return unless @project.editable?

        @instance = @project.instance_to_edit(
          created_by: current_user,
          has_supervisor_comment: has_supervisor_comment
        )
        new_instance_created = @instance.new_record?

        # Set title
        title_field_id = params[:fields].keys.first if params[:fields].present?
        @instance.title = params[:fields][title_field_id] if title_field_id.present?

        # Timestamps
        @instance.last_edit_time = Time.current
        @instance.last_edit_by = current_user.id

        raise StandardError unless @instance.save

        raise StandardError unless params[:fields].present?

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

        raise StandardError, 'Please choose a lecturer and topic' if params[:based_on_topic].blank?

        # 2 formats, PROJECT_ID or own_proposal_LECTURER_ID
        if params[:based_on_topic].start_with?('own_proposal_')
          # Extract lecturer ID from value
          lecturer_id = params[:based_on_topic].split('_').last.to_i

          # Find lecturer enrolment for course
          supervisor_enrolment = Enrolment.find_by(id: lecturer_id, course_id: @course.id, role: :lecturer)

          raise StandardError unless supervisor_enrolment

          @instance.update!(source_topic_id: nil)
        else
          # Treat as topic_id
          topic = Topic.find_by(id: params[:based_on_topic], course: @course)

          raise StandardError unless topic

          raise StandardError unless topic.owner.is_a?(User)

          supervisor_enrolment = Enrolment.find_by(user_id: topic.owner.id, course_id: @course.id, role: :lecturer)

          raise StandardError unless supervisor_enrolment

          @instance.update!(source_topic: topic)
        end

        @project.project_instances.last.update!(
          enrolment: supervisor_enrolment
        )
      end
    rescue StandardError
      redirect_to course_project_path(@course, @project), alert: 'Project update failed'
      return
    end

    if previous_supervisor_id != @project.supervisor.id || new_instance_created
      GeneralMailer.with(
        supervisor_username: @project.supervisor.username,
        owner_name: @course.grouped? ? @project.owner.group_name : @project.owner.username,
        course: @course,
        project: @project
      ).New_Student_Submission.deliver_later
    end

    redirect_to course_project_path(@course, @project), notice: 'Project updated successfully.'
  end

  def selected_topic
    topic_id = params[:topic_id].presence || params[:based_on_topic]

    @template_fields = @course.project_template.project_template_fields.where(applicable_to: %i[proposals both])

    if topic_id.start_with?('own_proposal_')

      # Own Proposal
      @field_values = {}
    else
      # Topics chosen
      topic = Topic.find(topic_id)
      latest_instance = topic.current_instance

      # Sorts by id
      @field_values = latest_instance.project_instance_fields.each_with_object({}) do |f, h|
        h[f.project_template_field_id] = f.value
      end
    end

    render partial: 'project_new',
           locals: { template_fields: @template_fields,
                     field_values: @field_values,
                     input_classes: 'w-full px-4 py-3 border border-gray-200 rounded-lg sm:rounded-xl text-gray-700 bg-gray-50 focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500 transition-all font-medium placeholder-gray-400 text-sm sm:text-base' }
  end

  def selected_topic_edit
    topic_id = params[:based_on_topic]

    @template_fields = @course.project_template.project_template_fields.where(applicable_to: %i[proposals both])

    if topic_id.start_with?('own_proposal_')
      # Does not load
      @existing_values = {}
    else
      # Chosen Topic
      topic = Topic.find(topic_id)
      latest_instance = topic.current_instance

      # Sorts by id
      @existing_values = latest_instance.project_instance_fields.each_with_object({}) do |f, h|
        h[f.project_template_field_id] = f.value
      end
    end

    render partial: 'project_edit',
           locals: { template_fields: @template_fields,
                     existing_values: @existing_values,
                     input_classes: 'w-full px-4 py-3 border border-gray-200 rounded-lg sm:rounded-xl text-gray-700 bg-gray-50 focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-blue-500 transition-all font-medium placeholder-gray-400 text-sm sm:text-base' }
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_project
    @project = @course.projects.find_by(id: params[:id])
  end
end
