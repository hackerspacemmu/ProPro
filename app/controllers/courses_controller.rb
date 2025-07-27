require "csv"
require "set"
require "securerandom"

class CoursesController < ApplicationController
    def show
        @course = Course.find(params[:id])
        
        if @course.grouped?
            @group = current_user.project_groups.joins(:project_group_members).find_by(project_group_members: {course_id: @course.id})
            @project = Project.find_by(ownership: @group)
            @group_list = @course.project_group

        else
            @group = nil
            @project = Project.find_by(ownership: current_user, course_id: @course.id)

        end

        
        #@description = @course.project_template.description errors out since project_template has no desc
        @student_list = @course.enrolments.where(role: :student).includes(:user).map(&:user)
        @lecturers = @course.enrolments.where(role: :lecturer).includes(:user).map(&:user)
        @topic_list = @course.projects.joins(:ownership).where(ownerships: { ownership_type: :lecturer })
        @students_with_projects = @student_list.select do |student|students_with_projects.include?(student.id) end
        @students_without_projects = @student_list.reject do |student|students_with_projects.include?(student.id) end

    end

    def new
      if !Current.user.is_staff
        redirect_to "/", alert: "Only staff can create courses"
        return
      end

      @new_course = Course.new
    end

    def add_people
      begin
        @course = Course.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_back_or_to "/", alert: "Invalid Course ID"
        return
      end

      if Current.user.is_staff && !Current.user.courses.include?(@course)
        redirect_back_or_to "/", alert: "Permission denied"
        return
      end
    end

    def handle_add_people
      begin
        @course = Course.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_back_or_to "/", alert: "Invalid Course ID"
        return
      end

      if Current.user.is_staff && !Current.user.courses.include?(@course)
        redirect_back_or_to "/", alert: "Permission denied"
        return
      end

      unregistered_students = Set[]
      unregistered_lecturers = Set[]


      if params[:invited_lecturers].blank?
        redirect_back_or_to "/", alert: "Invited lecturers cannot be empty"
        return
      end

      lecturer_emails = params[:invited_lecturers].split(";").map {|email| email.strip}

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

          create_lecturer_enrolments(lecturer_emails, @course, unregistered_lecturers)
        end
      rescue StandardError => e
        redirect_back_or_to "/", alert: e.message
        return
      end

      send_emails(unregistered_students, unregistered_lecturers)
      redirect_to "/", notice: "Success"
    end

    def create
      if !Current.user.is_staff
        redirect_to "/", alert: "Only staff can create courses"
        return
      end

      response = params.require(:course).permit(:course_name, :grouped)

      @new_course = Course.new(
        course_name: response[:course_name],
        grouped: response[:grouped],
      )

      begin
        ActiveRecord::Base.transaction do
          if !@new_course.save
            render :new, status: :unprocessable_entity
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
      rescue StandardError => e
        @new_course.destroy
        redirect_back_or_to "/", alert: "Course creation failed"
      end

      redirect_to add_people_course_path(@new_course), notice: "Course successfully created"
    end
  end

  private
  def students_with_projects
      Project.joins(:ownership).where(course_id: @course.id, ownerships: { ownership_type: :student, owner_type: "User" })
      .where.not(status: :rejected)
      .pluck("ownerships.owner_id")
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

        unregistered_students.add({:email_address => group_member[:email_address], :otp_token => new_otp_instance.token, :otp => new_otp_instance.otp})
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

  def send_emails(unregistered_students, unregistered_lecturers)
    unregistered_students.each do |student|
      GeneralMailer.with(email_address: student[:email_address], otp_token: student[:otp_token], otp: student[:otp]).send_student_invite.deliver_now
    end

    unregistered_lecturers.each do |lecturer|
      GeneralMailer.with(email_address: lecturer[:email_address], otp_token: lecturer[:otp_token], otp: lecturer[:otp]).send_lecturer_invite.deliver_now
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

        unregistered_students.add({:email_address => student[:email_address], :otp_token => new_otp_instance.token, :otp => new_otp_instance.otp})
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
          is_staff: true
        )

        new_otp_instance = Otp.create!(
          user: new_lecturer,
          otp: SecureRandom.base64(8),
          token: SecureRandom.uuid
        )

        unregistered_lecturers.add({:email_address => email, :otp_token => new_otp_instance.token, :otp => new_otp_instance.otp})
      end

      new_enrolment = Enrolment.find_or_create_by!(
        user: new_lecturer,
        course: parent_course,
        role: :lecturer
      )
    end
  end
end
