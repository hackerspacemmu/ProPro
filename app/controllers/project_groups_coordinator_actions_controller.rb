class ProjectGroupsCoordinatorActionsController < ApplicationController
  before_action :set_course
  before_action :set_group, only: %i[add remove move]
  before_action :authorize_coordinator!

  def add
    user = User.find(params[:user_id])

    begin
      @group.add_member!(user, is_coordinator: true)
      redirect_to coordinator_actions_course_project_groups_path(@course), notice: "#{user.name} added to group."
    rescue StandardError => e
      redirect_to coordinator_actions_course_project_groups_path(@course), alert: e.message
    end
  end

  def remove
    user = User.find(params[:user_id])

    if @group.remove_member!(user)
      redirect_to coordinator_actions_course_project_groups_path(@course), notice: "#{user.name} removed from group."
    else
      redirect_to coordinator_actions_course_project_groups_path(@course), alert: 'Failed to remove user.'
    end
  end

  def move
    user = User.find(params[:user_id])
    target_group = @course.project_groups.find(params[:target_group_id])

    begin
      ActiveRecord::Base.transaction do
        @group.remove_member!(user)
        target_group.add_member!(user, is_coordinator: true)
      end

      redirect_to coordinator_actions_course_project_groups_path(@course), notice: "#{user.name} moved successfully."
    rescue StandardError => e
      redirect_to coordinator_actions_course_project_groups_path(@course), alert: e.message
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:project_group_id])
  end

  def authorize_coordinator!
    authorize @course, :grouping_coordinator?
  end
end
