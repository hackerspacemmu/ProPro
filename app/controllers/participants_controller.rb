class ParticipantsController < ApplicationController
  def index
    @course = Course.find(params[:course_id])
    @student_list = @course.students
    @group_list = @course.grouped? ? @course.project_groups.to_a : []

    @filtered_group_list = filtered_group_list
    @filtered_student_list = filtered_student_list

    projects_ownerships = @course.projects.approved
                                 .where(owner_type: 'User')
                                 .pluck('owner_id')

    @students_with_projects = @student_list.select do |student|
      projects_ownerships.include?(student.id)
    end

    @students_without_projects = @student_list.reject do |student|
      projects_ownerships.include?(student.id)
    end
  end

  private

  def filtered_group_list
    return @group_list unless params[:status_filter].present? && params[:status_filter] != 'all'

    @course.groups_with_status(params[:status_filter], @group_list, @course)
  end

  def filtered_student_list
    return @student_list unless params[:status_filter].present? && params[:status_filter] != 'all'

    @course.students_with_status(params[:status_filter], @student_list, @students_with_projects, @students_without_projects, @course)
  end
end
