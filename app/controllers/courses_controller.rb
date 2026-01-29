require 'csv'
require 'securerandom'

class CoursesController < ApplicationController
  before_action :disallow_noncoordinator_requests, only: %i[add_students handle_add_students add_lecturers handle_add_lecturers settings handle_settings destroy export_csv]
  before_action :check_staff, only: %i[new create]
  before_action :access_topics, only: :show

  def show
    @student_list = @course.students
    @description = @course.course_description
    @lecturers = @course.lecturers
    @group_list = @course.grouped? ? @course.project_groups.to_a : []
    @lecturer_enrolment = @course.enrolments.find_by(user: current_user, role: :lecturer)

    # SET STUDENT PROJECTS
    projects_ownerships = @course.projects.approved
                                 .where(owner_type: 'User')
                                 .pluck('owner_id')

    @students_with_projects = @student_list.select do |student|
      projects_ownerships.include?(student.id)
    end

    @students_without_projects = @student_list.reject do |student|
      projects_ownerships.include?(student.id)
    end

    @filtered_group_list   = filtered_group_list
    @filtered_student_list = filtered_student_list
    @my_student_projects = []
    @incoming_proposals = []

    if @course.grouped?
      @group = current_user.project_groups.find_by(course: @course)

      @project = (@course.projects.find_by(owner_type: 'ProjectGroup', owner_id: @group.id) if @group)
    else
      @group = nil
      @project = @course.projects.find_by(owner_type: 'User', owner_id: current_user.id)
    end

    @current_status = @project&.current_status || 'not_submitted'

    if @current_user_enrolment&.coordinator?
      supervisor_enrolment = @lecturer_enrolment || @current_user_enrolment
      @my_student_projects = @course.projects.supervised_by(supervisor_enrolment).approved
      @incoming_proposals = @course.projects.where(enrolment: supervisor_enrolment).proposals
    elsif @current_user_enrolment&.lecturer?
      @my_student_projects = @course.projects.supervised_by(@current_user_enrolment).approved
      @incoming_proposals = @course.projects.where(enrolment: @current_user_enrolment).proposals
    end

    # SET LECTURER CAPACITY INFO
    @lecturer_capacity_info = {}
    @lecturers.each do |lecturer|
      @lecturer_capacity_info[lecturer.id] = lecturer_capacity_info(lecturer, @course)
    end

    return unless request.headers['HX-Request'] && params[:status_filter].present?

    render partial: 'participants_table',
           locals: {
             course: @course,
             group_list: @filtered_group_list,
             student_list: @filtered_student_list,
             students_with_projects: @students_with_projects,
             students_without_projects: @students_without_projects,
             use_progress_updates: @course.use_progress_updates
           }
    nil
  end

  def add_students; end

  def add_lecturers; end

  def handle_add_lecturers
    unregistered_lecturers = Set[]

    if params[:invited_lecturers].blank?
      redirect_back_or_to '/', alert: 'Invited lecturers cannot be empty'
      return
    end

    lecturer_emails = params[:invited_lecturers].split(';').map { |email| email.strip }

    begin
      ActiveRecord::Base.transaction do
        create_lecturer_enrolments(lecturer_emails, @course, unregistered_lecturers)
      end

      if @course.grouped
        @course.update(supervisor_projects_limit: (@course.project_groups.count / @course.lecturers.count).ceil)
      else
        @course.update(supervisor_projects_limit: (@course.students.count / @course.lecturers.count).ceil)
      end
    rescue StandardError => e
      redirect_back_or_to '/', alert: e.message
      return
    end

    send_emails(unregistered_lecturers)

    redirect_to course_path(@course)
  end

  def handle_add_students
    unregistered_students = Set[]

    if params[:csv_file].blank? || params[:csv_file].content_type != 'text/csv'
      redirect_back_or_to '/', alert: 'Please provide a CSV file from ebwise'
      return
    end

    begin
      csv_obj = CSV.parse(params[:csv_file].read, headers: true, liberal_parsing: true)
    rescue StandardError
      redirect_back_or_to '/', alert: 'CSV parsing failed'
      return
    end

    columns_to_check = ['Last name', 'ID number', 'Email address']

    columns_to_check.each do |column|
      unless csv_obj.headers.include? column
        redirect_back_or_to '/', alert: 'CSV file missing required headers'
        return
      end
    end

    if @course.grouped && !csv_obj.headers.include?('Group')
      redirect_back_or_to '/', alert: 'Not grouped CSV file'
      return
    end

    begin
      ActiveRecord::Base.transaction do
        # Remove the leading 'S-' from student IDs if present
        csv_obj.each do |row|
          student_id = row['ID number']
          row['ID number'] = student_id&.replace(student_id[2..]) if student_id&.start_with?('S-')
        end

        if @course.grouped
          student_hashmap = parse_csv_grouped(csv_obj, columns_to_check)
          create_db_entries_grouped(student_hashmap, @course, unregistered_students)
        else
          student_set = parse_csv_solo(csv_obj, columns_to_check)
          create_db_entries_solo(student_set, @course, unregistered_students)
        end

        if @course.grouped
          @course.update(supervisor_projects_limit: (@course.project_groups.count / @course.lecturers.count).ceil)
        else
          @course.update(supervisor_projects_limit: (@course.students.count / @course.lecturers.count).ceil)
        end
      end
    rescue StandardError => e
      redirect_back_or_to '/', alert: e.message
      return
    end

    send_emails(unregistered_students)
    redirect_to course_path(@course)
  end

  def new
    @new_course = Course.new
    @courses = current_user.courses.order(created_at: :desc).distinct
  end

  def create
    response = params.require(:course).permit(:course_name, :grouped)

    @new_course = Course.new(
      course_name: response[:course_name],
      grouped: response[:grouped]
    )

    begin
      ActiveRecord::Base.transaction do
        raise StandardError, 'Course failed verification' unless @new_course.save

        Enrolment.create!(
          user: Current.user,
          course: @new_course,
          role: :coordinator
        )

        Enrolment.create!(
          user: Current.user,
          course: @new_course,
          role: :lecturer
        )

        default_template = @new_course.build_project_template

        raise StandardError, 'Template creation failed' unless default_template.save
      end
    rescue StandardError
      @new_course.destroy
      render :new, status: :unprocessable_entity
      return
    end

    redirect_to course_path(@new_course), notice: 'Course successfully created'
  end

  def settings; end

  def handle_settings
    @course.update(
      course_name: params[:course][:course_name],
      course_description: params[:course][:course_description],
      supervisor_projects_limit: params[:course][:supervisor_projects_limit],
      require_coordinator_approval: params[:course][:require_coordinator_approval],
      starting_week: params[:course][:starting_week],
      use_progress_updates: params[:course][:use_progress_updates],
      number_of_updates: params[:course][:number_of_updates],
      lecturer_access: params[:course][:lecturer_access],
      student_access: params[:course][:student_access],
      file_link: params[:course][:file_link]
    )

    unless @course.save
      render :settings, status: :unprocessable_entity
      return
    end

    redirect_to settings_course_path(@course), notice: 'Course successfully updated'
  end

  def destroy
    @course.destroy
    redirect_to '/'
  end

  def profile
    @participant_type = params[:participant_type]
    @participant_id = params[:participant_id]
    @course = Course.find(params[:id])

    @grouped = @course.grouped

    if @participant_type == 'group'
      @group = @course.project_groups.find(@participant_id)
      @members = @group.project_group_members.includes(:user)
    else
      @student = User.find(@participant_id)
    end

    @latest_instance = @project&.project_instances&.order(:version)&.last
    Rails.logger.info "PROFILE PARAMS: #{params.slice(:id, :participant_id, :participant_type).inspect}"
  end

  def export_csv
    @student_list = @course.enrolments.where(role: :student).includes(:user).map(&:user)
    @group_list = @course.grouped? ? @course.project_groups.includes(project_group_members: :user).to_a : []

    csv_content = generate_csv_export

    filename = "#{@course.course_name.parameterize}.csv"
    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}\""

    render plain: csv_content
  end

  private

  def students_with_projects
    @course.projects.not_lecturer_owned.approved.where(owner_type: 'User').pluck('owner_id')
  end

  def disallow_noncoordinator_requests
    @course = Course.find(params[:id])

    return if @course.coordinators.include? Current.user

    redirect_back_or_to '/', alert: 'Access denied'
    nil
  end

  def check_staff
    return if Current.user.is_staff

    redirect_to '/', alert: 'Only staff can create courses'
    nil
  end

  def parse_csv_grouped(csv_obj, columns_to_check)
    ret = {}

    csv_obj.each do |row|
      mapped_columns = columns_to_check.map { |item| row[item] }
      # in the csv, an empty group still has a row, just that all columns of that row are not populated, this is valid
      next if mapped_columns.all?(&:nil?)

      # if it passed the previous check, it means that the current row is not ALL empty, but ONE OF the columns might still be, this is invalid
      mapped_columns.each do |column|
        raise StandardError, 'Invalid CSV file' if column.nil?
      end

      group = row['Group'].strip

      if ret.key?(group)
        ret[group].add({ name: row['Last name'].strip, student_id: row['ID number'].strip, email_address: row['Email address'].strip })
      else
        ret[group] = Set[{ name: row['Last name'].strip, student_id: row['ID number'].strip, email_address: row['Email address'].strip }]
      end
    end

    ret
  end

  def create_db_entries_grouped(hash_map, parent_course, unregistered_students)
    hash_map.keys.each do |group|
      new_group = ProjectGroup.find_or_create_by!(group_name: group, course: parent_course)

      hash_map[group].each do |group_member|
        new_user = User.find_by(email_address: group_member[:email_address], is_staff: false)

        if new_user
          new_user.update!(student_id: group_member[:student_id])
        else
          new_user = User.create!(
            email_address: group_member[:email_address],
            username: group_member[:name],
            password: SecureRandom.base64(24),
            has_registered: false,
            student_id: group_member[:student_id],
            is_staff: false
          )

          new_otp_instance = Otp.create!(
            user: new_user,
            otp: SecureRandom.base64(8),
            token: SecureRandom.uuid
          )

          unregistered_students.add(
            {
              email_address: group_member[:email_address],
              otp_token: new_otp_instance.token,
              otp: new_otp_instance.otp,
              is_staff: false
            }
          )
        end

        Enrolment.find_or_create_by!(
          user: new_user,
          course: parent_course,
          role: :student
        )

        new_group_member = ProjectGroupMember.find_by(user: new_user, project_group: new_group)

        if new_group_member
          new_group_member.update!(project_group: new_group)
        else
          ProjectGroupMember.create!(
            user: new_user,
            project_group: new_group
          )
        end
      end
    end
  end

  def send_emails(unregistered_users)
    unregistered_users.each do |user|
      GeneralMailer.with(
        email_address: user[:email_address],
        otp_token: user[:otp_token],
        otp: user[:otp],
        is_staff: user[:is_staff]
      ).ProPro_Invite.deliver_later
    end
  end

  def parse_csv_solo(csv_obj, columns_to_check)
    ret = Set[]

    csv_obj.each do |row|
      mapped_columns = columns_to_check.map { |item| row[item] }

      mapped_columns.each do |column|
        raise StandardError, 'Invalid CSV file' if column.nil?
      end

      ret.add({ name: row['Last name'].strip, student_id: row['ID number'].strip, email_address: row['Email address'].strip })
    end

    ret
  end

  def create_db_entries_solo(student_set, parent_course, unregistered_students)
    student_set.each do |student|
      new_user = User.find_by(email_address: student[:email_address], is_staff: false)

      if new_user
        new_user.update!(student_id: student[:student_id])
      else
        new_user = User.create!(
          email_address: student[:email_address],
          username: student[:name],
          password: SecureRandom.base64(24),
          has_registered: false,
          student_id: student[:student_id],
          is_staff: false
        )

        new_otp_instance = Otp.create!(
          user: new_user,
          otp: SecureRandom.base64(8),
          token: SecureRandom.uuid
        )

        unregistered_students.add(
          {
            email_address: student[:email_address],
            otp_token: new_otp_instance.token,
            otp: new_otp_instance.otp,
            is_staff: false
          }
        )
      end

      Enrolment.find_or_create_by!(
        user: new_user,
        course: parent_course,
        role: :student
      )
    end
  end

  def create_lecturer_enrolments(lecturer_emails, parent_course, unregistered_lecturers)
    lecturer_emails.each do |email|
      next if email.blank?

      new_lecturer = User.find_by(email_address: email, is_staff: true)

      unless new_lecturer
        new_lecturer = User.create!(
          email_address: email,
          password: SecureRandom.base64(24),
          has_registered: false,
          is_staff: true,
          username: "Lecturer-#{SecureRandom.hex(2)}"
        )

        new_otp_instance = Otp.create!(
          user: new_lecturer,
          otp: SecureRandom.base64(8),
          token: SecureRandom.uuid
        )

        unregistered_lecturers.add(
          {
            email_address: email,
            otp_token: new_otp_instance.token,
            otp: new_otp_instance.otp,
            is_staff: true
          }
        )
      end

      Enrolment.find_or_create_by!(
        user: new_lecturer,
        course: parent_course,
        role: :lecturer
      )
    end
  end

  def generate_csv_export
    template_fields = @course.project_template&.project_template_fields&.order(:id) || []

    CSV.generate do |csv|
      csv << build_csv_headers(template_fields)

      if @course.grouped?
        @group_list.each do |group|
          build_group_rows(group, template_fields).each { |row| csv << row }
        end
      else
        @student_list.each do |student|
          build_student_rows(student, template_fields).each { |row| csv << row }
        end
      end
    end
  end

  def build_csv_headers(template_fields)
    headers = %w[Student_Name Student_ID Email_Address]
    headers << 'Student Group' if @course.grouped?
    headers += %w[Supervisor_Name Supervisor_Email_Address Project_Title Project_Status]

    # Project Title is handled by validation in Project.rb
    template_fields = template_fields.reject { |field| field.label == 'Project Title' }
    project_fields = template_fields.select do |field|
      field.proposals? || field.both?
    end

    project_fields.each do |field|
      headers << field.label
    end
    headers
  end

  def build_group_rows(group, template_fields)
    project = @course.projects.find_by(owner_type: 'ProjectGroup', owner_id: group.id)
    current_instance = project&.current_instance
    supervisor = project&.supervisor
    project_status = project&.current_status || 'not_submitted'
    field_values = get_project_details_values(current_instance, template_fields)
    rows = []

    group.project_group_members.each do |member|
      user = member.user
      row = [
        user.username || '',
        user.student_id || '',
        user.email_address || '',
        group.group_name || '',
        supervisor&.username || '',
        supervisor&.email_address || '',
        project&.current_title || '',
        project_status.humanize
      ]
      row.concat(field_values)
      rows << row
    end
    rows
  end

  def build_student_rows(student, template_fields)
    project = @course.projects.find_by(owner_type: 'User', owner_id: student.id)
    current_instance = project&.current_instance
    supervisor = project&.supervisor
    project_status = project&.current_status || 'not_submitted'
    field_values = get_project_details_values(current_instance, template_fields)

    row = [
      student.username || '',
      student.student_id || '',
      student.email_address || '',
      supervisor&.username || '',
      supervisor&.email_address || '',
      project&.current_title || '',
      project_status.humanize
    ]

    row.concat(field_values)
    [row]
  end

  def get_project_details_values(current_instance, template_fields)
    return [] unless current_instance

    project_fields = template_fields.select do |field|
      %w[proposals both].include?(field.applicable_to)
    end.reject { |field| field.label == 'Project Title' }

    return Array.new(project_fields.count, '') if project_fields.empty?

    instance_fields = current_instance.project_instance_fields.includes(:project_template_field).index_by(&:project_template_field_id)

    project_fields.map do |template_field|
      field = instance_fields[template_field.id]
      if field&.value.present?
        if template_field.dropdown? || template_field.radio?
          begin
            parsed_value = JSON.parse(field.value)
            parsed_value.is_a?(Array) ? parsed_value.join(', ') : parsed_value.to_s
          rescue JSON::ParserError
            field.value.to_s
          end
        else
          field.value
        end
      else
        ''
      end
    end
  end

  def access_topics
    @course = Course.find(params[:id])
    coordinator_enrolment = @course.enrolments.find_by(user: Current.user, role: :coordinator)
    lecturer_enrolment = @course.enrolments.find_by(user: Current.user, role: :lecturer)
    student_enrolment = @course.enrolments.find_by(user: Current.user, role: :student)

    @current_user_enrolment = if coordinator_enrolment
                                coordinator_enrolment
                              elsif lecturer_enrolment
                                lecturer_enrolment
                              else
                                student_enrolment
                              end

    # 1) Coordinator: sees all topics (any status)
    if @current_user_enrolment&.coordinator?
      @topic_list = @course.topics

    # Lecturer: sees their own topics (any status)
    # plus other lecturers’ only if approved
    elsif @current_user_enrolment&.lecturer?
      own = @course.topics.where(owner_id: current_user.id)

      approved = @course.topics.where(status: :approved)

      @topic_list = own.or(approved)

    # Students: see only approved topics
    else
      @topic_list = @course.topics.where(status: :approved)
    end
  end

  def lecturer_approved_proposals_count(lecturer, course)
    lecturer_enrolment = course.enrolments.find_by(user: lecturer, role: :lecturer)
    return 0 unless lecturer_enrolment

    course.projects.supervised_by(lecturer_enrolment).approved.count
  end

  def lecturer_pending_proposals_count(lecturer, course)
    lecturer_enrolment = course.enrolments.find_by(user: lecturer, role: :lecturer)
    return 0 unless lecturer_enrolment

    course.projects.supervised_by(lecturer_enrolment).pending_redo.count
  end

  def lecturer_capacity_info(lecturer, course)
    approved_count = lecturer_approved_proposals_count(lecturer, course)
    pending_count = lecturer_pending_proposals_count(lecturer, course)
    max_capacity = course.supervisor_projects_limit

    {
      approved_proposals: approved_count,
      pending_proposals: pending_count,
      total_proposals: approved_count + pending_count,
      max_capacity: max_capacity,
      remaining_capacity: [max_capacity - approved_count, 0].max,
      is_at_capacity: approved_count >= max_capacity
    }
  end

  def students_by_status(status, student_list, students_with_projects, students_without_projects, course)
    return [] unless student_list.present?

    case status
    when 'approved'
      students_with_projects || []
    when 'pending', 'redo', 'rejected'
      student_list.select do |student|
        project = course.projects
                        .find_by(owner_type: 'User', owner_id: student.id)
        project&.current_status == status
      end
    when 'not_submitted'
      students_without_projects || []
    else
      []
    end
  end

  def groups_by_status(status, group_list, course)
    return [] unless group_list.present?

    case status
    when 'approved'
      group_list.select do |group|
        project = course.projects
                        .find_by(owner_type: 'ProjectGroup', owner_id: group.id)
        project&.current_status == 'approved'
      end
    when 'pending', 'redo', 'rejected'
      group_list.select do |group|
        project = course.projects
                        .find_by(owner_type: 'ProjectGroup', owner_id: group.id)
        project&.current_status == status
      end
    when 'not_submitted'
      group_list.select do |group|
        project = course.projects
                        .find_by(owner_type: 'ProjectGroup', owner_id: group.id)
        project.nil?
      end
    else
      []
    end
  end

  def filtered_group_list
    group_list = if params[:status_filter].present? && params[:status_filter] != 'all'
                   groups_by_status(params[:status_filter], @group_list, @course)
                 else
                   @group_list
                 end
    group_list.sort_by(&:group_name)
  end

  def filtered_student_list
    return @student_list unless params[:status_filter].present? && params[:status_filter] != 'all'

    students_by_status(params[:status_filter], @student_list, @students_with_projects, @students_without_projects, @course)
  end
end
