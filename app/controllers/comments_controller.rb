class CommentsController < ApplicationController
  def new; end

  def create
    return if params[:comment][:source_id].blank? || params[:comment][:source_type].blank? || params[:comment][:user_comment].blank?

    return unless %w[TopicInstance ProjectInstance].include? params[:comment][:source_type]

    location = params[:comment][:source_type].constantize.find(params[:comment][:source_id])

    comment = Comment.new(
      user: Current.user,
      location: location,
      text: params[:comment][:user_comment]
    )

    authorize comment

    comment.save!

    notify_project_comment(comment, location) if params[:comment][:source_type] == 'ProjectInstance'

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

  private

  def notify_project_comment(comment, project_instance)
    project = project_instance.project

    recipients = (CommentPolicy.project_members(project) + [CommentPolicy.project_supervisor(project)])
                 .compact
                 .uniq
                 .reject { |u| u == Current.user }

    recipients.each do |recipient|
      GeneralMailer.with(
        email_address: recipient.email_address,
        recipient: recipient.name,
        commenter_name: Current.user.name,
        comment_snippet: comment.text.truncate(50),
        course: project.course,
        project: project
      ).Project_Comment_Notification.deliver_later
    end
  end
end