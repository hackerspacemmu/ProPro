class CommentPolicy < ApplicationPolicy
  def create?
    return false unless latest_version?
    
    case record.location_type
    when "ProjectInstance"
      can_comment_on_project?
    when "TopicInstance"
      can_comment_on_topic?
    else
      false
    end
  end
  
  def destroy?
    own_comment? && !deleted?
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
    when "ProjectInstance"
      project = record.location.project
      record.location == project.project_instances.order(:version).last
    when "TopicInstance"
      topic = record.location.topic
      record.location == topic.topic_instances.order(:version).last
    else
      false
    end
  end
  
  def can_comment_on_project?
    project_instance = record.location
    project = project_instance.project
    course = project.course
    
    return true if course.enrolments.exists?(user: user, role: :coordinator)
    return true if project.supervisor == user
    
    if project.owner_type == "User"
      project.owner_id == user.id
    elsif project.owner_type == "ProjectGroup"
      project.owner.users.include?(user)
    else
      false
    end
  end
  
  def can_comment_on_topic?
    topic_instance = record.location
    topic = topic_instance.topic
    course = topic.course
    
    return true if course.enrolments.exists?(user: user, role: :coordinator)
    return true if topic.owner == user
  end
end