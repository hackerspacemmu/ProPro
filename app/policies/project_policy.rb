class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if coordinator?
        scope.all
      else
        scope.select { |project| viewable?(project) }
      end
    end

    private

    def coordinator?
      course.enrolments.exists?(user: user, role: :coordinator)
    end

    def viewable?(project)
      # Proposals
      return true if student_proposal?(project)
      # Topics
      return true if approved_lecturer_topic?(project)
      false
    end

    def student_proposal?(project)
      owner = project.owner
      return true if owner.is_a?(User) && 
                     course.enrolments.exists?(user: owner, role: :student)
      return true if owner.is_a?(ProjectGroup) &&
                     owner.users.all? { |u| course.enrolments.exists?(user: u, role: :student) }
      false
    end

    def approved_lecturer_topic?(project)
      project.lecturer? && project.status.to_s == "approved"
    end

    def course
      @course ||= scope.first&.course
    end
  end

  def show?
    coordinator? || 
      own_project? || 
      own_supervisor? ||
      unrestricted_access?
  end

  def update?
    own_project? || (coordinator? && record.student?)
  end

  def change_status?
    record.supervisor == user
  end

  private

  def coordinator?
    course.enrolments.exists?(user: user, role: :coordinator)
  end

  def own_project?
    record.owner == user ||
      (record.owner.is_a?(ProjectGroup) && record.owner.users.include?(user))
  end

  def own_supervisor?
    return false unless course.student_access.to_s == "own_lecturer_only"
    record.supervisor == user
  end

  def unrestricted_access?
    course.student_access.to_s == "no_restriction"
  end

  def course
    record.course
  end
end