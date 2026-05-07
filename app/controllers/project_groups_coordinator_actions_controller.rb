class ProjectGroupsCoordinatorActionsController < ApplicationController
  def add
    user = User.find(params[:user_id])

    begin
      @group.add_member!(user, is_coordinator: true)
      redirect_to course_project_groups_path(@course), notice: "#{user.name} added to group."
    rescue StandardError => e
      # handle error for when the user is already in another group
      redirect_to course_project_groups_path(@course), alert: e.message
    end
  end

  def remove
    user = User.find(params[:user_id])

    if @group.remove_member!(user)
      redirect_to course_project_groups_path(@course), notice: "#{user.name} removed from group."
    else
      redirect_to course_project_groups_path(@course), alert: 'Failed to remove user.'
    end
  end

  def move
    user = User.find(params[:user_id])
    target_group = @course.project_groups.find(params[:target_group_id])

    begin
      transaction do
        @group.remove_member!(user)
        target_group.add_member(user, is_coordinator: true)
      end
      redirect_to course_project_groups_path(@course), notice: "#{user.name} moved successfully."
    rescue StandardError => e
      redirect_to course_project_groups_path(@course), alert: e.message
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:project_group_id])
  end

  # for ensuring the user is actually the coordinator
  def authorize_coordinator!
    authorize @course, :grouping_coordinator?
  end
end
