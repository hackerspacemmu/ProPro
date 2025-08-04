class CommentsController < ApplicationController
  def new
  end

  def create
    parent_project = Project.find(params[:project_id])
    parent_course = Course.find(params[:course_id])
    @type = parent_project.ownership&.ownership_type

    if Current.user.nil?
      return
    end

    if !parent_course.grouped
      unless Current.user == User.find(parent_project.ownership.owner_id) || Current.user == parent_project.supervisor
        return
      end
    else
      group_members = ProjectGroup.find(parent_project.ownership.owner_id).project_group_members.map { |member| User.find(member.user_id) }

      unless group_members.includes? Current.user || Current.user == parent_project.supervisor
        return
      end
    end

    Comment.create!(
      user: Current.user,
      project: parent_project,
      text: params[:comment][:user_comment]
      )

    if @type == "student"
      redirect_to course_project_path(parent_course, parent_project)
    else
      redirect_to course_topic_path(parent_course, parent_project)
    end
  end

  def soft_delete
    parent_project = Project.find(params[:project_id])
    parent_course = Course.find(params[:course_id])
    @type = parent_project.ownership&.ownership_type
    comment = Comment.find(params[:id])

    if Current.user.nil?
      return
    end

    if Current.user == comment.user
      comment.update!(deleted: true)
    end

    if @type == "student"
      redirect_to course_project_path(parent_course, parent_project)
    else
      redirect_to course_topic_path(parent_course, parent_project)
    end

   Rails.logger.info params
  end
end


