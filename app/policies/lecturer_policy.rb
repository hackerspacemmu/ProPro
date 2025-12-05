class LecturerPolicy < ApplicationPolicy
  def show?
    coordinator? || 
      viewing_self? ||
      (lecturer? && course.lecturer_access) ||
      student?
  end

  def full_access?
    coordinator? || viewing_self? || (lecturer? && course.lecturer_access)
  end

  def own_supervisor?
    return false unless student?
    return false unless lecturer_enrolment

    user_group_ids = user.project_groups.where(course: course).pluck(:id)
    
    course.projects.supervised_by(lecturer_enrolment).where(
      "(owner_type = 'User' AND owner_id = ?) OR 
       (owner_type = 'ProjectGroup' AND owner_id IN (?))",
       user.id, user_group_ids
    ).exists?
  end

  private

  def coordinator?
    course.enrolments.exists?(user: user, role: :coordinator)
  end

  def lecturer?
    course.enrolments.exists?(user: user, role: :lecturer)
  end

  def student?
    course.enrolments.exists?(user: user, role: :student)
  end

  def viewing_self?
    record == user
  end

  def lecturer_enrolment
    course.enrolments.find_by(user: record, role: :lecturer)
  end

  def course
    @course 
  end
end