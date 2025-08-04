module ProjectsHelper
  def project_viewable_by_current_user?(course, project)
    # Coordinators can see everything
    return true if course.enrolments.exists?(user: current_user, role: :coordinator)
    
    owner = project.ownership&.owner

    # 1) Student-owned proposals (all statuses except rejected are OK)
    return true if owner.is_a?(User) &&
                   course.enrolments.exists?(user: owner, role: :student)

    # 2) Group-owned proposals (all members are students)
    return true if owner.is_a?(ProjectGroup) &&
                   owner.users.all? { |u| course.enrolments.exists?(user: u, role: :student) }

    # 3) Lecturer-proposed topics, but only once approved
    return true if project.ownership.lecturer? && project.status.to_s == "approved"

    false
  end
end