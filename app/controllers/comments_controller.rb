class CommentsController < ApplicationController
  def new; end

  def create
    return if params[:comment][:source_id].blank? || params[:comment][:source_type].blank? || params[:comment][:user_comment].blank?

    return unless %w[TopicInstance ProjectInstance].include? params[:comment][:source_type]

    location = params[:comment][:source_type].constantize.find(params[:comment][:source_id])

    case params[:comment][:source_type]
    when 'TopicInstance'
      whitelist = location.topic.course.coordinators.pluck(:id) << location.topic.owner.id
    when 'ProjectInstance'
      whitelist = location.project.course.coordinators.pluck(:id) << location.project.supervisor.id

      if location.project.course.grouped?
        whitelist += location.project.owner.project_group_members.pluck(:user_id)
      else
        whitelist << location.project.owner.id
      end
    end

    return unless whitelist.include? Current.user.id

    Comment.create!(
      user: Current.user,
      location: location,
      text: params[:comment][:user_comment]
    )

    case params[:comment][:source_type]
    when 'ProjectInstance'
      redirect_to course_project_path(location.project.course, location.project, version: location.version)
    when 'TopicInstance'
      redirect_to course_topic_path(location.topic.course, location.topic, version: location.version)
    end
  end

  def soft_delete
    comment = Comment.find(params[:id])

    comment.update!(deleted: true) if Current.user.id == comment.user.id

    case comment.location_type
    when 'ProjectInstance'
      redirect_to course_project_path(comment.location.project.course, comment.location.project, version: comment.location.version)
    when 'TopicInstance'
      redirect_to course_topic_path(comment.location.topic.course, comment.location.topic, version: comment.location.version)
    end
  end
end
