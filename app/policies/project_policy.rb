class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.all if coordinator
      
      if student && course.student_access.to_s == "owner_only"
        own_projects
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

    def own_projects
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
      is_project_owner ||
      is_assigned_supervisor ||
      has_unrestricted_student_access
  end

  def create?
    student || coordinator
  end
  
  def update?
    is_project_owner && !approved
  end
  
  def change_status?
    is_assigned_supervisor
  end

  def can_record_progress_update?
    is_assigned_supervisor && approved && course.use_progress_updates
  end
  
  # PROJECT ACCESS METHODS
  def has_lecturer_view_access
    lecturer && course.lecturer_access
  end
  
  def is_project_owner
    record.owner == user || (record.owner.is_a?(ProjectGroup) && record.owner.users.include?(user))
  end
  
  def is_assigned_supervisor
    record.supervisor == user
  end
  
  def has_unrestricted_student_access
    student && course.student_access.to_s == "no_restriction"
  end
  
  def coordinator
    course.enrolments.exists?(user: user, role: :coordinator)
  end
  
  def lecturer
    course.enrolments.exists?(user: user, role: :lecturer)
  end
  
  def course
    record.course
  end

  def student
    course.enrolments.exists?(user: user, role: :student)
  end
  
  def course
    record.course
  end

  def approved
    record.status.to_s == "approved"
  end
end