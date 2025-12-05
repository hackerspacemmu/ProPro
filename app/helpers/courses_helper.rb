module CoursesHelper
  def group_project_for(group, course)
    @group_projects_cache ||= {}
    @group_projects_cache[group.id] ||= course.projects
      .find_by(owner_type: 'ProjectGroup', owner_id: group.id)
  end
  
  def student_project_for(student, course)
    @student_projects_cache ||= {}
    @student_projects_cache[student.id] ||= course.projects
      .find_by(owner_type: 'User', owner_id: student.id)
  end

  def group_status(group, course)
    project = group_project_for(group, course)
    return 'not_submitted' unless project
    project.current_status
  end
  
  def student_status(student, course)
    project = student_project_for(student, course)
    return 'not_submitted' unless project
    project.current_status
  end

  def participants_exceed?(course)
    return false unless course.students.present? 
    course.students.count > Rails.application.config.participants_threshold
  end

  def supervisors_exceed?(course)
    return false unless course.supervisors.present?
    course.supervisors.count > Rails.application.config.supervisors_threshold
  end
end
