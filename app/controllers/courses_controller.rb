require "csv"

class CoursesController < ApplicationController
  allow_unauthenticated_access only: %i[ new create]
    def show
        @course = Course.find(params[:id])
        @group = current_user.project_groups.joins(:enrolments).find_by(enrolments: { course_id: @course.id })
        @project = Project.find_by(group_id: @group.id)
        @project_template = @course.project_template
        @lecturer = supervisor.projects.where(enrolment: { course_id: @course.id }).count
    end

    def new
    end

    def create
      if !Current.user
        redirect_back_or_to "/", alert: params
        return
      end
      
      if !Current.user.is_staff
        return
      end

      response = params.permit(:course_name, :require_coordinator_approval, :grouped, :use_progress_updates, :number_of_progress_updates, :lecturer_access, :student_access, :invited_lecturers)

      if response[:course_name].blank?
        redirect_back_or_to "/", alert: "Course name cannot be empty"
        return
      end
      
      if response[:require_coordinator_approval].blank?
        redirect_back_or_to "/", alert: "Require coordinator approval cannot be empty"
        return
      elsif response[:require_coordinator_approval] != "true" and response[:require_coordinator_approval] != "false"
        return
      end

      if response[:grouped].blank?
        redirect_back_or_to "/", alert: "Grouped cannot be empty"
        return
      elsif response[:grouped] != "true" and response[:grouped] != "false"
        return
      end
      
      if response[:use_progress_updates].blank?
        redirect_back_or_to "/", alert: "Progress updates cannot be empty"
        return

      elsif response[:use_progress_updates] == "true"
        number_of_progress_updates = response[:number_of_progress_updates].to_i

        if response[:number_of_progress_updates].blank?
          redirect_back_or_to "/", alert: "Number of progress updates cannot be empty"
          return
        elsif response[:number_of_progress_updates].include? "."
          redirect_back_or_to "/", alert: "Number of progress updates cannot be float"
          return
        elsif number_of_progress_updates <= 0 # "fjdsajfad".to_i returns 0, there can never be -ve updates
          redirect_back_or_to "/", alert: "Invalid number of progress updates"
        end

      elsif response[:use_progress_updates] == "false"
        number_of_progress_updates = -1 # -1 for no progress updates
      else
        return
      end

      if response[:lecturer_access].blank?
        redirect_back_or_to "/", alert: "Lecturer access cannot be empty"
        return
      elsif response[:lecturer_access] != "true" and response[:lecturer_access] != "false"
        return
      end

      if response[:student_access].blank?
        redirect_back_or_to "/", alert: "Student access cannot be empty"
        return
      end

      unless Course.student_accesses.keys.include?(response[:student_access])
        return
      end
      
      if response[:invited_lecturers].blank?
        redirect_back_or_to "/", alert: "Invited lecturers cannot be empty"
        return
      end
=begin
      if new_course = Course.create(course_name: response[:course_name], )
      else
      end
=end
    end
    
    private
    def parse_csv(grouped, file)
      if grouped
      else
      end
    end
end
