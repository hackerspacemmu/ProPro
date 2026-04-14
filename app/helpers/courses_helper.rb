module CoursesHelper
  def group_project_for(group, _course)
    @projects_by_owner[['ProjectGroup', group.id]]
  end

  def student_project_for(student, _course)
    @projects_by_owner[['User', student.id]]
  end

  def group_status(group, course)
    group_project_for(group, course)&.current_status || 'not_submitted'
  end

  def student_status(student, course)
    student_project_for(student, course)&.current_status || 'not_submitted'
  end

  def participants_exceed?(course)
    course.students.size > Rails.application.config.participants_threshold
  end

  def supervisors_exceed?(course)
    course.supervisors.size > Rails.application.config.supervisors_threshold
  end
end
