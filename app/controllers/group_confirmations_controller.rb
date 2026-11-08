class GroupConfirmationsController < ApplicationController
  include RequiresGroupedCourse

  before_action :set_course
  before_action :ensure_grouped
  before_action :set_group

  def create
    authorize @group, :confirm?

    result = GroupConfirmer.new(@group).confirm!

    if result.confirmed?
      redirect_to course_group_formation_path(@course), notice: result.message
    else
      redirect_to course_group_formation_path(@course), alert: result.message
    end
  end

  def destroy
    authorize @group, :revert?

    result = GroupReverter.new(@group).revert!

    if result.reverted?
      redirect_to course_group_formation_path(@course), notice: result.message
    else
      redirect_to course_group_formation_path(@course), alert: result.message
    end
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:group_id])
  end
end
