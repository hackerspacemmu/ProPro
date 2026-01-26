class TopicPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      enrolment = course.enrolments.find_by(user: user)
      
      case enrolment&.role
      when "coordinator"
        scope.all
      when "lecturer"
        scope.where(owner: user).or(scope.where(status: :approved))
      else
        scope.where(status: :approved)
      end
    end

    private

    # SCOPE METHODS, DO NOT USE IN POLICIES
    def course
      @course ||= scope.first&.course
    end
  end

  # POLICY METHODS
  def show?
    coordinator || own_topic || approved
  end

  def update?
    coordinator || own_topic
  end

  def change_status?
    coordinator && course.require_coordinator_approval?
  end

  def new?
    user.is_staff
  end

  def destroy?
    own_topic
  end

  def coordinator
    course.enrolments.exists?(user: user, role: :coordinator)
  end

  def own_topic
    course.enrolments.exists?(user: user, role: :lecturer) && record.owner == user
  end

  def approved
    record.status.to_s == "approved"
  end

  def course
    record.course
  end
end