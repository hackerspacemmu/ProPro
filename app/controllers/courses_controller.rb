require "csv"
require "set"
require "securerandom"

class CoursesController < ApplicationController
    before_action :disallow_noncoordinator_requests, only: [ :add_students, :handle_add_students, :add_lecturers, :handle_add_lecturers, :settings, :handle_settings, :destroy ]
    before_action :check_staff, only: [ :new, :create ]
    before_action :access_topics, only: :show


    def show
      @student_list = @course.enrolments.where(role: :student).includes(:user).map(&:user)
      @description = @course.course_description
      @student_list = @course.enrolments.where(role: :student).includes(:user).map(&:user)
      @lecturers = @course.enrolments.where(role: :lecturer).includes(:user).map(&:user)
      @group_list = @course.grouped? ? @course.project_groups.to_a : []
      @my_student_projects = []
      @incoming_proposals = []

      if @course.grouped?
        @group = current_user.project_groups.find_by(course: @course)
        
        if @group
          group_ownership = Ownership.find_by(
            owner_type: @group.class.name,
            owner_id: @group.id,
            ownership_type: :student  
            )
          @project = group_ownership ? Project.find_by(ownership: group_ownership, course: @course) : nil
        else
          @project = nil
        end
      else
          @group = nil
          user_ownership = Ownership.find_by(
            owner_type: "User",
            owner_id: current_user.id,
            ownership_type: :student  
          )
          @project = user_ownership ? Project.find_by(ownership: user_ownership, course: @course) : nil

      end
    
    # SET COORDINATOR & LECTURER VARIABLES
    if @current_user_enrolment&.coordinator?
      @my_student_projects = @course.projects.approved_student_proposals
      @incoming_proposals = @course.projects.pending_student_proposals
    elsif @current_user_enrolment&.lecturer?
      @my_student_projects = @course.projects.approved_for_lecturer(@current_user_enrolment)
      @incoming_proposals = @course.projects.pending_for_lecturer(@current_user_enrolment)
    end
      
      # SET LECTURER CAPACITY INFO
      @lecturer_capacity_info = {}
      @lecturers.each do |lecturer|
        @lecturer_capacity_info[lecturer.id] = lecturer_capacity_info(lecturer, @course)
      end

      # SET STUDENT PROJECTS
      projects_ownerships = @course.projects.approved_student_proposals
      .joins(:ownership)
      .where(ownerships: { owner_type: "User" })
      .pluck("ownerships.owner_id")
  
      @students_with_projects = @student_list.select do |student|
        projects_ownerships.include?(student.id)
      end 

      @students_without_projects = @student_list.reject do |student|
        projects_ownerships.include?(student.id)
      end
    end

    def add_students
    end

    def add_lecturers
    end

    def handle_add_lecturers
      unregistered_lecturers = Set[]

      if params[:invited_lecturers].blank?
        redirect_back_or_to "/", alert: "Invited lecturers cannot be empty"
        return
      end

      lecturer_emails = params[:invited_lecturers].split(";").map {|email| email.strip}

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
        redirect_back_or_to "/", alert: e.message
        return
      end

      send_emails(unregistered_lecturers)

      redirect_to add_students_course_path(@course)
    end

    def handle_add_students
      unregistered_students = Set[]

      if params[:csv_file].blank? || params[:csv_file].content_type != "text/csv"
        redirect_back_or_to "/", alert: "Please provide a CSV file from ebwise"
        return
      end

      begin
        csv_obj = CSV.parse(params[:csv_file].read, headers: true, liberal_parsing: true)
      rescue StandardError => e
        redirect_back_or_to "/", alert: "CSV parsing failed"
        return
      end

      columns_to_check = ["Last name", "ID number", "Email address"]

      columns_to_check.each do |column|
        if !csv_obj.headers.include? column
          redirect_back_or_to "/", alert: "CSV file missing required headers"
          return
        end
      end

      if @course.grouped && !csv_obj.headers.include?("Group")
        redirect_back_or_to "/", alert: "Not grouped CSV file"
        return
      end

      begin
        ActiveRecord::Base.transaction do
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
        redirect_back_or_to "/", alert: e.message
        return
      end

      send_emails(unregistered_students)
      redirect_to settings_course_path(@course)
    end

    def new
      @new_course = Course.new
    end

    def create
      response = params.require(:course).permit(:course_name, :grouped)

      @new_course = Course.new(
        course_name: response[:course_name],
        grouped: response[:grouped]
      )

      begin
        ActiveRecord::Base.transaction do
          if !@new_course.save
            raise StandardError, "Course failed verification"
          end

          new_coordinator_enrolment = Enrolment.create!(
            user: Current.user,
            course: @new_course,
            role: :coordinator
          )

          new_lecturer_enrolment = Enrolment.create!(
            user: Current.user,
            course: @new_course,
            role: :lecturer
          )

          default_template = @new_course.build_project_template

          if !default_template.save
            raise StandardError, "Template creation failed"
          end
        end
      rescue StandardError => e
        @new_course.destroy
        render :new, status: :unprocessable_entity
        return
      end

    redirect_to add_lecturers_course_path(@new_course), notice: "Course successfully created"
  end

  def settings
  end

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

    if !@course.save
      render :settings, status: :unprocessable_entity
      return
    end

    redirect_to settings_course_path(@course), notice: "Course successfully updated"
  end

  def destroy
    @course.destroy
    redirect_to "/"
  end

  private
  def students_with_projects
    @course.projects.approved_student_proposals.joins(:ownership).where(ownerships: { owner_type: "User" }).pluck("ownerships.owner_id")
  end

  def disallow_noncoordinator_requests
    @course = Course.find(params[:id])

    unless Current.user == @course.coordinator.user
      redirect_back_or_to "/", alert: "Access denied"
      return
    end
  end

  def check_staff
    if !Current.user.is_staff
      redirect_to "/", alert: "Only staff can create courses"
      return
    end
  end

  def parse_csv_grouped(csv_obj, columns_to_check)
    ret = {}

    csv_obj.each do |row|
      mapped_columns = columns_to_check.map { |item| row[item] }
      # in the csv, an empty group still has a row, just that all columns of that row are not populated, this is valid
      if mapped_columns.all?(&:nil?) 
        next
      end

      # if it passed the previous check, it means that the current row is not ALL empty, but ONE OF the columns might still be, this is invalid
      mapped_columns.each do |column|
        if column.nil?
          raise StandardError, "Invalid CSV file"
        end
      end

      group = row["Group"].strip

      if ret.key?(group)
        ret[group].add({:name => row["Last name"].strip, :student_id => row["ID number"].strip, :email_address => row["Email address"].strip})
      else
        ret[group] = Set[{:name => row["Last name"].strip, :student_id => row["ID number"].strip, :email_address => row["Email address"].strip}]
      end
    end

    return ret
  end

  def create_db_entries_grouped(hash_map, parent_course, unregistered_students)
    hash_map.keys.each do |group|
      new_group = ProjectGroup.find_or_create_by!(group_name: group, course: parent_course)

      hash_map[group].each do |group_member|
        new_user = User.find_by(email_address: group_member[:email_address], is_staff: false)

        if !new_user
          new_user = User.create!(
            email_address: group_member[:email_address],
            username: group_member[:name],
            password: SecureRandom.base64(24),
            has_registered: false,
            student_id: group_member[:student_id],
            is_staff: false,
          )

          new_otp_instance = Otp.create!(
            user: new_user,
            otp: SecureRandom.base64(8),
            token: SecureRandom.uuid
          )

        unregistered_students.add(
          {
           :email_address => group_member[:email_address],
           :otp_token => new_otp_instance.token,
           :otp => new_otp_instance.otp,
           :is_staff => false
          }
        )
        else
          new_user.update!(student_id: group_member[:student_id])
        end

        new_enrolment = Enrolment.find_or_create_by!(
          user: new_user,
          course: parent_course,
          role: :student
        )

        new_group_member = ProjectGroupMember.find_by(user: new_user)

        if new_group_member
          new_group_member.update!(project_group: new_group)
        else
          new_group_member = ProjectGroupMember.create!(
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
      ).ProPro_Invite.deliver_now
    end
  end

  def parse_csv_solo(csv_obj, columns_to_check)
    ret = Set[]

    csv_obj.each do |row|
      mapped_columns = columns_to_check.map { |item| row[item] }

      mapped_columns.each do |column| 
        if column.nil?
          raise StandardError, "Invalid CSV file"
        end
      end

      ret.add({:name => row["Last name"].strip, :student_id => row["ID number"].strip, :email_address => row["Email address"].strip})
    end

    return ret
  end

  def create_db_entries_solo(student_set, parent_course, unregistered_students)
    student_set.each do |student|
      new_user = User.find_by(email_address: student[:email_address], is_staff: false)

      if !new_user
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
           :email_address => student[:email_address],
           :otp_token => new_otp_instance.token,
           :otp => new_otp_instance.otp,
           :is_staff => false
          }
        )
      else
        new_user.update!(student_id: student[:student_id])
      end

      new_enrolment = Enrolment.find_or_create_by!(
        user: new_user,
        course: parent_course,
        role: :student
      )
    end
  end

  def create_lecturer_enrolments(lecturer_emails, parent_course, unregistered_lecturers)
    lecturer_emails.each do |email|
      if email.blank?
        next
      end

      new_lecturer = User.find_by(email_address: email, is_staff: true)

      if !new_lecturer
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
           :email_address => email,
           :otp_token => new_otp_instance.token,
           :otp => new_otp_instance.otp,
           :is_staff => true
          }
        )
      end

      new_enrolment = Enrolment.find_or_create_by!(
        user: new_lecturer,
        course: parent_course,
        role: :lecturer
      )
    end
  end


def access_topics
  @course                 = Course.find(params[:id])
  @current_user_enrolment = @course.enrolments.find_by(user: current_user)

  lt = Ownership.ownership_types[:lecturer]

  # 1) Coordinator: sees all topics (any status)
  if @current_user_enrolment&.coordinator?
    @topic_list = @course.projects
                         .joins(:ownership)
                         .where(ownerships: { ownership_type: lt })

  # Lecturer: sees their own topics (any status)
  # plus other lecturers’ only if approved
  elsif @current_user_enrolment&.lecturer?
    own = @course.projects
                 .joins(:ownership)
                 .where(ownerships: {
                   owner_type:     "User",
                   owner_id:       current_user.id,
                   ownership_type: lt
                 })

    approved = @course.projects
                      .joins(:ownership)
                      .where(ownerships: { ownership_type: lt },
                             status:     :approved)

    @topic_list = own.or(approved)

  #Students: see only approved topics
  else
    @topic_list = @course.projects
                         .joins(:ownership)
                         .where(ownerships: { ownership_type: lt },
                                status:     :approved)
  end
end

def lecturer_approved_proposals_count(lecturer, course)
  lecturer_enrolment = course.enrolments.find_by(user: lecturer, role: :lecturer)
  return 0 unless lecturer_enrolment
  
  course.projects.approved_for_lecturer(lecturer_enrolment).count
end

def lecturer_pending_proposals_count(lecturer, course)
  lecturer_enrolment = course.enrolments.find_by(user: lecturer, role: :lecturer)
  return 0 unless lecturer_enrolment
  
  course.projects.pending_for_lecturer(lecturer_enrolment).count
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
    is_at_capacity: approved_count >= max_capacity,
  }
end
end

