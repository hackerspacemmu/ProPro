class CommentPolicy < ApplicationPolicy
  def create?
    return false unless latest_version?

    case record.location_type
    when 'ProjectInstance'
      can_comment_on_project?
    when 'TopicInstance'
      can_comment_on_topic?
    else
      false
    end
  end

  def destroy?
    own_comment? && !deleted?
  end

  class << self
    def project_supervisor(project)
      project.supervisor
    end

    def project_coordinators(course)
      course.enrolments.where(role: :coordinator).map(&:user)
    end

    def project_members(project)
      project.owner_type == 'ProjectGroup' ? project.owner.users : [project.owner]
    end
  end

  private

  def own_comment?
    user == record.user
  end

  def deleted?
    record.deleted?
  end

  def latest_version?
    case record.location_type
    when 'ProjectInstance'
      project = record.location.project
      record.location == project.project_instances.order(:version).last
    when 'TopicInstance'
      topic = record.location.topic
      record.location == topic.topic_instances.order(:version).last
    else
      false
    end
  end

  def can_comment_on_project?
    project = record.location.project

    return true if self.class.project_coordinators(project.course).include?(user)
    return true if self.class.project_supervisor(project) == user

    self.class.project_members(project).include?(user)
  end

  def can_comment_on_topic?
    topic_instance = record.location
    topic = topic_instance.topic
    course = topic.course

    return true if course.enrolments.exists?(user: user, role: :coordinator)

    true if topic.owner == user
  end
end
