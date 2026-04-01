class ParticipantsController < ApplicationController
  def index
    @course = Course.find(params[:course_id])
    authorize @course

    # query for all projects_instances, owner_type and owner_id for participants table
    @course.projects.includes(project_instances: { enrolment: :user }).load
    @projects_by_owner = @course.projects.index_by { |p| [p.owner_type, p.owner_id]

    @student_list = @course.students

    if @course.grouped?
      @group_list = @course.project_groups.includes(project_group_members: :user).to_a
    else 
      @group_list = []
    end

    projects_ownerships = @course.projects.approved.where(owner_type: 'User').pluck('owner_id')

    @filtered_group_list = filtered_group_list
    @filtered_student_list = filtered_student_list

    @students_with_projects = @student_list.select { |s| projects_ownerships.include?(s.id) }
    @students_without_projects = @student_list.reject { |s| projects_ownerships.include?(s.id) }
    end
  end

  private

  def filtered_group_list
    group_list = if params[:status_filter].present? && params[:status_filter] != 'all'
                   @course.groups_with_status(params[:status_filter], @group_list)
                 else
                   @group_list
                 end
    group_list.sort_by(&:group_name)
  end

  def filtered_student_list
    return @student_list unless params[:status_filter].present? && params[:status_filter] != 'all'

    @course.students_with_status(params[:status_filter], @student_list)
  end
end
