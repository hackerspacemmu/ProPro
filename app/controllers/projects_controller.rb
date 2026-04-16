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

    @comments = @project.comments.order(created_at: :asc)
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
      supervisor_name: Current.user.name
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

    # Choose Supervisor
    @lecturers = @course.lecturers
    @lecturer_capacity_info = {}
    @lecturers.each do |lecturer|
      @lecturer_capacity_info[lecturer.id] = @course.lecturer_capacity(lecturer)
    end

    @field_values = {}

    if params[:topic_id].present?
      @selected_topic = @course.topics.find_by(id: params[:topic_id])
      if @selected_topic
        latest_instance = @selected_topic.current_instance
        @field_values = latest_instance.project_instance_fields.each_with_object({}) do |f, h|
          h[f.project_template_field_id.to_i] = f.value
        end
      end
    elsif params[:lecturer_id].present?
      @selected_lecturer = @course.lecturers.find_by(id: params[:lecturer_id])
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

        topic = Topic.find_by(id: params[:based_on_topic], course: @course) if params[:based_on_topic].present?
        lecturer_id = params[:lecturer_id].presence

        raise StandardError, 'Please choose a lecturer or topic' if topic.nil? && lecturer_id.nil?

        if topic
          topic_owner = topic.owner
          raise StandardError, 'Topic has no valid owner' unless topic_owner.is_a?(User)

          supervisor_enrolment = Enrolment.find_by(user_id: topic_owner.id, course_id: @course.id, role: :lecturer)
          raise StandardError, 'Could not find supervisor enrolment' unless supervisor_enrolment
        else
          supervisor_enrolment = Enrolment.find_by(user_id: lecturer_id, course_id: @course.id, role: :lecturer)
          raise StandardError, 'Could not find supervisor enrolment' unless supervisor_enrolment
        end

        @project = Project.create!(
          course: @course,
          owner: @course.grouped? ? group : current_user,
          supervisor_enrolment: supervisor_enrolment
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
          supervisor_enrolment: supervisor_enrolment,
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
      supervisor_name: @project.supervisor.name,
      owner_name: @course.grouped? ? @project.owner.group_name : @project.owner.name,
      course: @course,
      project: @project
    ).New_Student_Submission.deliver_later

    redirect_to course_project_path(@course, @project), notice: 'Project created!'
  end

  def update
    authorize @project || Project.new(course: @course)
    is_approved = @project.approved?

    last_instance = @project.project_instances.last
    has_supervisor_comment = last_instance.comments.exists?(user_id: @project.supervisor.id)

    previous_supervisor_id = @project.supervisor.id
    new_instance_created = false

    begin
      ActiveRecord::Base.transaction do
        raise StandardError, 'This project is locked and cannot be edited.' unless @project.editable? || is_approved

        @instance = @project.instance_to_edit(
          created_by: current_user,
          has_supervisor_comment: has_supervisor_comment
        )
        new_instance_created = @instance.new_record?

        if new_instance_created
          previous_instance = @project.project_instances.order(version: :desc).first

          previous_instance.project_instance_fields.each do |old_field|
            @instance.project_instance_fields.build(
              project_template_field_id: old_field.project_template_field_id,
              value: old_field.value
            )
          end
        end

        raise StandardError, 'No field data provided.' if params[:fields].blank?

        params[:fields].each do |field_id, value|
          template_field = ProjectTemplateField.find(field_id)

          next if is_approved && !template_field.free_edit

          field = @instance.project_instance_fields.find { |f| f.project_template_field_id == field_id.to_i }

          field = @instance.project_instance_fields.build(project_template_field_id: field_id.to_i) if field.nil?

          field.value = value
          field.save!
        end

        raise StandardError, 'Please choose a lecturer or topic' unless params[:based_on_topic].present?

        if params[:based_on_topic].include? 'own_proposal_'
          lecturer_id = params[:based_on_topic][13...]
        else
          topic = Topic.find_by(id: params[:based_on_topic], course: @course)
        end

        if topic
          raise StandardError, 'Topic has no valid owner' unless topic.owner.is_a?(User)

          supervisor_enrolment = Enrolment.find_by(user_id: topic.owner.id, course_id: @course.id, role: :lecturer)

          raise StandardError, 'Could not find supervisor enrolment' unless supervisor_enrolment

          @instance.update!(source_topic: topic, supervisor_enrolment: supervisor_enrolment)
        else
          supervisor_enrolment = Enrolment.find_by(id: lecturer_id, course_id: @course.id, role: :lecturer)

          raise StandardError, 'Could not find supervisor enrolment' unless supervisor_enrolment

          @instance.update!(source_topic_id: nil, supervisor_enrolment: supervisor_enrolment)
        end
      end
    rescue StandardError => e
      redirect_to course_project_path(@course, @project), alert: "Project update failed: #{e.message}"
      return
    end

    if previous_supervisor_id != @project.supervisor.id || new_instance_created
      GeneralMailer.with(
        supervisor_name: @project.supervisor.name,
        owner_name: @course.grouped? ? @project.owner.group_name : @project.owner.name,
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
    return if @project

    redirect_to course_path(@course), alert: 'Project not found.' and return
  end
end
