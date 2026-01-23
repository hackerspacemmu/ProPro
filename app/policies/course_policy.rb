class CoursePolicy < ApplicationPolicy
  def show?
    enrolled
  end
  
  def promote_to_coordinator?
    coordinator
  end
  
  def demote_to_lecturer?
    coordinator && record.coordinators.count > 1
  end
  
  # LECTURER PROFILE
  def unrestricted_lecturer_access?(lecturer)
    coordinator ||
      user == lecturer ||
      (lecturer && record.lecturer_access)
  end

  def student_can_view_lecturer?(lecturer)
    return false unless student

    case record.student_access&.to_sym
    when :no_restriction
      true
    when :own_lecturer_only
      supervised_by?(lecturer)
    when :owner_only
      record.projects.where(owner: user).supervised_by?(lecturer)
    else
      false
    end
  end
  
  def supervised_by?(lecturer)
    return false unless student
    
    lecturer_enrolment = record.enrolments.find_by(user: lecturer, role: :lecturer)
    return false unless lecturer_enrolment
    
    record.projects
      .supervised_by(lecturer_enrolment)
      .owned_by_student_or_groups(user, user.project_groups.where(course: record))
      .exists?
  end
  
  private
  
  def coordinator
    record.enrolments.exists?(user: user, role: :coordinator)
  end
  
  def lecturer
    record.enrolments.exists?(user: user, role: :lecturer)
  end
  
  def student
    record.enrolments.exists?(user: user, role: :student)
  end
  
  def enrolled
    record.enrolments.exists?(user: user)
  end
end