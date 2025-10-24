class ProjectsController < ApplicationController
  before_action :access

  def show
    if @project.nil?
      redirect_to course_path(@course), alert: "Project not found or access denied." and return
    end

    @instances = @project.project_instances.order(version: :asc)
    @owner = @project.owner
    @status = @project.status

    @lecturers = @course.lecturers

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

    @current_fields = @current_instance.project_instance_fields.includes(:project_template_field).order(project_template_field_id: :asc)

    @latest_version = @instances.size

    @next_fields = nil

    if @index < @instances.size
      @next_instance = @instances[@index]
      @next_fields = @next_instance.project_instance_fields.includes(:project_template_field).order(project_template_field_id: :asc)
    end

    @comments = @current_instance.comments
    @new_comment = Comment.new

    if @course.use_progress_updates
      @progress = @project.progress_updates.order(date: :desc)
      @weeks = @course.number_of_updates
    end
  end

  def change_status
    if current_user != @project.supervisor
      redirect_to course_project_path(@course, @project), alert: "You are not authorized to perform this action."
      return
    end

    new_status = params[:status]
    @project.project_instances.last.update!(status: new_status)

    GeneralMailer.with(
      course: @course,
      project: @project,
      supervisor_username: Current.user.username
    ).Project_Status_Updated.deliver_later

    redirect_to course_project_path(@course, @project), notice: "Status updated to #{new_status.humanize}."
  end

  def edit
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

  def update
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
        if @project.status == "approved"
          return
        elsif @project.status == "rejected" || @project.status == "redo" || (@project.status == "pending" && has_supervisor_comment)
          version = @project.project_instances.count + 1
          @instance = @project.project_instances.build(
            version: version,
            created_by: current_user,
            enrolment: @project.enrolment
          )
          new_instance_created = true
        else
          @instance = @project.project_instances.last
        end

        # Set title
        title_field_id = params[:fields].keys.first if params[:fields].present?
        @instance.title = params[:fields][title_field_id] if title_field_id.present?

        if !@instance.save
          raise StandardError
        end

        if !params[:fields].present?
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

        if params[:based_on_topic].blank?
          raise StandardError, "Please choose a lecturer and topic"
        end

        # 2 formats, PROJECT_ID or own_proposal_LECTURER_ID
        if params[:based_on_topic].start_with?("own_proposal_")
          # Extract lecturer ID from value
          lecturer_id = params[:based_on_topic].split("_").last.to_i

          # Find lecturer enrolment for course
          supervisor_enrolment = Enrolment.find_by(id: lecturer_id, course_id: @course.id, role: :lecturer)

          if !supervisor_enrolment
            raise StandardError
          end

          @instance.update!(source_topic_id: nil)
        else
          # Treat as topic_id
          topic = Topic.find_by(id: params[:based_on_topic], course: @course)

          if !topic
            raise StandardError
          end

          if !topic.owner.is_a?(User)
            raise StandardError
          end

          supervisor_enrolment = Enrolment.find_by(user_id: topic.owner.id, course_id: @course.id, role: :lecturer)

          if !supervisor_enrolment
            raise StandardError
          end

          @instance.update!(source_topic: topic)
        end

        @project.project_instances.last.update!(enrolment: supervisor_enrolment)
      end
    rescue StandardError => e
      redirect_to course_project_path(@course, @project), alert: "Project update failed"
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

    redirect_to course_project_path(@course, @project), notice: "Project updated successfully."
  end

  def new
    unless @is_student
      redirect_to course_path(@course), alert: "You are not authorized"
      return
    end

    if @course.grouped?
      has_project = Current.user.group_projects.find_by(course: @course).present?
    else
      has_project = Current.user.solo_projects.find_by(course: @course).present?
    end

    if has_project
      redirect_to course_path(@course), alert: "You already have a project in this course."
      return
    end

    @template_fields = @course.project_template.project_template_fields.where(applicable_to: [:proposals, :both])

    @lecturer_options = Enrolment.where(course: @course, role: :lecturer).includes(:user)

    # Optionally preselect topic or own proposal
    if params[:topic_id].present? && Project.exists?(id: params[:topic_id], course: @course)
      @selected_topic_id = params[:topic_id]
    end
  end

  def create
    @course = Course.find(params[:course_id])
    begin
      ActiveRecord::Base.transaction do
        if @course.grouped?
          group = current_user.project_groups.find_by(course: @course)

          unless group
            raise StandardError, "You're not part of a project group."
          end

          if group.project
            raise StandardError, "Your group already has a project"
          end
        else
          has_project = Current.user.solo_projects.find_by(course: @course)

          if has_project
            raise StandardError, "You already have a project"
          end
        end

        if params[:based_on_topic].blank?
          raise StandardError, "Please choose a lecturer and topic"
        end

        if params[:based_on_topic].start_with?("own_proposal_")
          # Extract lecturer ID from value
          lecturer_id = params[:based_on_topic].split("_").last.to_i

          # Find lecturer enrolment for course
          supervisor_enrolment = Enrolment.find_by(user_id: lecturer_id, course_id: @course.id, role: :lecturer)

          if !supervisor_enrolment
            raise StandardError
          end
        else
          # Treat as topic_id
          topic = Topic.find_by(id: params[:based_on_topic], course: @course)

          if !topic
            raise StandardError
          end
          # Set supervisor enrolment to the owner of the topic (assuming you want this)
          topic_owner = topic&.owner
          if !topic_owner.is_a?(User)
            raise StandardError
          end

          supervisor_enrolment = Enrolment.find_by(user_id: topic_owner.id, course_id: @course.id, role: :lecturer)

          if !supervisor_enrolment
            raise StandardError
          end
        end

        @project = Project.create!(
          course: @course,
          owner: @course.grouped? ? group : current_user,
          enrolment: supervisor_enrolment
        )

        # Get title
        title_value = nil
        params[:fields]&.each do |field_id, value|
          if ProjectTemplateField.find(field_id).label.strip.downcase.include?("title")
            title_value = value
          end
        end

        @instance = @project.project_instances.create!(
          version: 1,
          title: title_value,
          created_by: current_user,
          enrolment: supervisor_enrolment,
          source_topic: topic || nil
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

    redirect_to course_project_path(@course, @project), notice: "Project created!"
  end


  private
  def project_params
    params.require(:project).permit(:supervisor_id)
  end

  # make sure that same logic in helpers/projects_helper.rb
  def access
    @course = Course.find(params[:course_id])

    @is_student = @course.enrolments.exists?(user: current_user, role: :student)
    @is_coordinator = @course.enrolments.exists?(user: current_user, role: :coordinator)

    # Build the list of projects/topics visible to the current user:
    if @is_coordinator
      # Coordinators see everything
      @projects = @course.projects
    else
      # Non-coordinators:
      @projects = @course.projects.select do |project|
        owner = project&.owner

        # 1) Student-owned proposals (all statuses except rejected are OK)
        next true if owner.is_a?(User) &&
                    @course.enrolments.exists?(user: owner, role: :student)

        # 2) Group-owned proposals (all members are students)
        next true if owner.is_a?(ProjectGroup) &&
                    owner.users.all? { |u| @course.enrolments.exists?(user: u, role: :student) }

        # 3) Lecturer-proposed topics, but only once approved
        next true if project.lecturer? &&
                    project.status.to_s == "approved"                

        false
      end
    end

    if params[:id]
      @project = @projects.find { |p| p.id == params[:id].to_i }
      @instances = @project.project_instances.order(version: :asc)
      @index = @instances.size
      @latest_instance = @instances[@index - 1]
      return redirect_to(course_path(@course), alert: "You are not authorized") if @project.nil?
    end

    authorized = false

    if @course.enrolments.exists?(user: current_user, role: :coordinator)
      authorized = true

    elsif @course.lecturer_access && @course.lecturers.pluck(:id).include?(Current.user.id)
      authorized = true

    elsif @course.owner_only?
      authorized = @project.nil? || @project.owner == current_user

    elsif @course.own_lecturer_only?
      authorized = @project.nil? || (
        @project.owner == current_user ||
        @latest_instance.supervisor == current_user
      )
    elsif @course.no_restriction?
      authorized = true
    end

    @lecturers = @course.lecturers

    return redirect_to(course_path(@course), alert: "You are not authorized") unless authorized
  end
end
