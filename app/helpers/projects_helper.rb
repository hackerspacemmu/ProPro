module ProjectsHelper
  def project_viewable_by_current_user?(course, project)
    owner = project.ownership&.owner

    # 1) Student-owned proposals
    return true if owner.is_a?(User) &&
                   course.enrolments.exists?(user: owner, role: :student)

    # 2) Group-owned proposals
    return true if owner.is_a?(ProjectGroup) &&
                   owner.users.all? { |u| course.enrolments.exists?(user: u, role: :student) }

    # 3) Lecturer-proposed topics, but only once approved
    if project.ownership.ownership_type == "lecturer" && project.status.to_s == "approved"
      return true
    end

    # 4) Coordinators can see everything
    return true if course.enrolments.exists?(user: current_user, role: :coordinator)

    false
  end
end
