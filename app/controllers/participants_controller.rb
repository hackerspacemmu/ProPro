class ParticipantsController < ApplicationController
  def index
    @course = Course.find(params[:course_id])
    authorize @course

    # query for all projects_instances, owner_type and owner_id for participants table
    @course.projects.includes(project_instances: { enrolment: :user }).load
    @projects_by_owner = @course.projects.index_by { |p| [p.owner_type, p.owner_id] }

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

    @show_all = params[:show_all] == 'true'
    @total_count = @course.grouped? ? @filtered_group_list.count : @filtered_student_list.count

    unless @show_all
      @filtered_group_list = @filtered_group_list.first(Rails.application.config.participants_pagination_threshold)
      @filtered_student_list = @filtered_student_list.first(Rails.application.config.participants_pagination_threshold)
    end

    @displayed_count = @course.grouped? ? @filtered_group_list.count : @filtered_student_list.count
  end

  private

  def supervised_owner_ids(owner_type)
    return nil unless params[:lecturer_filter].present? && params[:lecturer_filter] != 'all'
    
    enrolment_ids = @course.enrolments.where(user_id: params[:lecturer_filter]).pluck(:id)
    return nil if enrolment_ids.empty?
    
    @course.projects.where(supervisor_enrolment_id: enrolment_ids, owner_type: owner_type).pluck(:owner_id)
  end

  def filtered_group_list
    group_list = @group_list

    if (ids = supervised_owner_ids('ProjectGroup'))
      group_list = group_list.select { |g| ids.include?(g.id) }
    end

    if params[:status_filter].present? && params[:status_filter] != 'all'
      group_list = @course.groups_with_status(params[:status_filter], group_list)
    end

    return group_list.sort_by(&:group_name)
  end

  def filtered_student_list
    student_list = @student_list

    if (ids = supervised_owner_ids('User'))
      student_list = student_list.select { |s| ids.include?(s.id) }
    end

    return student_list unless params[:status_filter].present? && params[:status_filter] != 'all'

    @course.students_with_status(params[:status_filter], student_list)
  end
end
