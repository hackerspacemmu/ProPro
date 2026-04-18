class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.all if coordinator

      if student && course.student_access.to_s == 'owner_only'
        own_project
      else
        viewable
      end
    end

    private

    # SCOPE METHODS, DO NOT USE IN POLICIES
    def viewable
      student_owned = scope.where(ownership_type: :student)
      group_owned = scope.where(ownership_type: :project_group)
      approved_topics = scope.where(ownership_type: :lecturer, status: :approved)

      student_owned.or(group_owned).or(approved_topics)
    end

    def own_project
      user_groups = user.project_groups.where(course: course)
      scope.owned_by_user_or_groups(user, user_groups)
    end

    def coordinator
      course.enrolments.exists?(user: user, role: :coordinator)
    end

    def student
      course.enrolments.exists?(user: user, role: :student)
    end

    def course
      @course ||= scope.take&.course
    end
  end

  # POLICY METHODS
  def show?
    coordinator ||
      has_lecturer_view_access ||
      project_owner ||
      assigned_supervisor ||
      has_unrestricted_student_access
  end

  def create?
    student && !has_existing_project?
  end

  def update?
    return true if project_owner && !approved

    return true if project_owner && approved && any_free_edit_fields?

    return true if coordinator

    false
  end

  def change_status?
    assigned_supervisor
  end

  def can_record_progress_update?
    assigned_supervisor && approved && course.use_progress_updates
  end

  # PROJECT ACCESS METHODS
  def has_lecturer_view_access
    lecturer && course.lecturer_access
  end

  def project_owner
    record.owner == user || (record.owner.is_a?(ProjectGroup) && record.owner.users.include?(user))
  end

  def assigned_supervisor
    record.supervisor == user
  end

  def has_unrestricted_student_access
    student && course.student_access.to_s == 'no_restriction'
  end

  def coordinator
    course.enrolments.exists?(user: user, role: :coordinator)
  end

  def lecturer
    course.enrolments.exists?(user: user, role: :lecturer)
  end

  delegate :course, to: :record

  def student
    course.enrolments.exists?(user: user, role: :student)
  end

  def approved
    record.status.to_s == 'approved'
  end

  def any_free_edit_fields?
    record.course.project_template
          &.project_template_fields
          &.exists?(free_edit: true) || false
  end

  def has_existing_project?
    user_groups = user.project_groups.where(course: course)

    course.projects
          .owned_by_user_or_groups(user, user_groups)
          .exists?
  end
end
