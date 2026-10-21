module CoursesHelper
  # All lookups take the owner->project mapping as an explicit argument rather
  # than reaching for a controller ivar. The caller (courses_controller#profile)
  # already builds projects_by_owner from @course.projects.index_by { ... }.
  def group_project_for(group, projects_by_owner)
    projects_by_owner[['ProjectGroup', group.id]]
  end

  def student_project_for(student, projects_by_owner)
    projects_by_owner[['User', student.id]]
  end

  def group_status(group, projects_by_owner)
    group_project_for(group, projects_by_owner)&.current_status || 'not_submitted'
  end

  def student_status(student, projects_by_owner)
    student_project_for(student, projects_by_owner)&.current_status || 'not_submitted'
  end
end
