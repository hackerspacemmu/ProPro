module CoursesHelper
  def group_project_for(group, course)
    @group_projects_cache ||= {}
    @group_projects_cache[group.id] ||= course.projects
      .joins(:ownership)
      .find_by(ownerships: { owner_type: 'ProjectGroup', owner_id: group.id })
  end

  def student_project_for(student, course)
    @student_projects_cache ||= {}
    @student_projects_cache[student.id] ||= course.projects
      .joins(:ownership)
      .find_by(ownerships: { owner_type: 'User', owner_id: student.id })
  end

  def students_by_status(status, student_list, students_with_projects, students_without_projects, course)
    return [] unless student_list.present?
    
    case status
    when 'approved'
      students_with_projects || []
    when 'pending', 'redo', 'rejected'
      student_list.select do |student|
        project = student_project_for(student, course)
        project&.status&.to_s == status
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
        project = group_project_for(group, course)
        project&.status&.to_s == 'approved'
      end
    when 'pending', 'redo', 'rejected'
      group_list.select do |group|
        project = group_project_for(group, course)
        project&.status&.to_s == status
      end
    when 'not_submitted'
      group_list.select do |group|
        project = group_project_for(group, course)
        project.nil?
      end
    else
      []
    end
  end

  def get_group_status(group, course)
    project = group_project_for(group, course)
    return 'not_submitted' unless project
    project.status.to_s
  end

  def get_student_status(student, course)
    project = student_project_for(student, course)
    return 'not_submitted' unless project
    project.status.to_s
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