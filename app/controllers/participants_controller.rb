class ParticipantsController < ApplicationController
    def index
        @course = Course.find(params[:course_id])
        @student_list = @course.students
        @group_list = @course.grouped? ? @course.project_groups.to_a : []

        @filtered_group_list = filtered_group_list
        @filtered_student_list = filtered_student_list

        projects_ownerships = @course.projects.approved 
                              .where(owner_type: "User")
                              .pluck("owner_id")

        @students_with_projects = @student_list.select do |student|
          projects_ownerships.include?(student.id)
        end 

        @students_without_projects = @student_list.reject do |student|
          projects_ownerships.include?(student.id)
        end
    end

    private

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
        return @group_list unless params[:status_filter].present? && params[:status_filter] != 'all'
        groups_by_status(params[:status_filter], @group_list, @course)
    end
    
    def filtered_student_list
        return @student_list unless params[:status_filter].present? && params[:status_filter] != 'all'
        students_by_status(params[:status_filter], @student_list, @students_with_projects, @students_without_projects, @course)
    end
end 