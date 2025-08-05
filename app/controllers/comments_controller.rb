class CommentsController < ApplicationController
  def new
  end

  def create
    parent_project = Project.find(params[:project_id])
    parent_course = parent_project.course
    type = parent_project.ownership&.ownership_type

    if Current.user.nil?
      return
    end

    whitelist = [parent_course.coordinator.user, parent_project.supervisor]

    if type == :student
      if !parent_course.grouped
        whitelist.push(parent_project.owner)
      else
        group_members = ProjectGroup.find(parent_project.ownership.owner_id).project_group_members

        group_members.each do |group_member|
          whitelist.push(group_member.user)
        end
      end
    end

    unless whitelist.include? Current.user
      return
    end

    Comment.create!(
      user: Current.user,
      project: parent_project,
      text: params[:comment][:user_comment]
      )

    if type == "student"
      redirect_to course_project_path(parent_course, parent_project)
    else
      redirect_to course_topic_path(parent_course, parent_project)
    end
  end

  def soft_delete
    parent_project = Project.find(params[:project_id])
    parent_course = parent_project.course
    type = parent_project.ownership&.ownership_type
    comment = Comment.find(params[:id])

    if Current.user.nil?
      return
    end

    if Current.user == comment.user
      comment.update!(deleted: true)
    end

    if type == "student"
      redirect_to course_project_path(parent_course, parent_project)
    else
      redirect_to course_topic_path(parent_course, parent_project)
    end

  end
end
