class GroupConfirmationsController < ApplicationController
  include RequiresGroupedCourse

  before_action :set_course
  before_action :ensure_grouped
  before_action :set_group

  def create
    authorize @group, :confirm?

    result = if policy(@course).manage_groups?
               Groups::Coordinator::Confirmer.new(@group).confirm!
             else
               GroupConfirmer.new(@group).confirm!
             end

    if result.confirmed?
      redirect_to return_target, notice: result.message
    else
      redirect_to return_target, alert: result.message
    end
  end

  def destroy
    authorize @group, :revert?

    result = if policy(@course).manage_groups?
               Groups::Coordinator::Reopener.new(@group).reopen!
             else
               GroupReverter.new(@group).revert!
             end

    if result.reverted?
      redirect_to return_target, notice: result.message
    else
      redirect_to return_target, alert: result.message
    end
  end

  private

  def return_target
    url_from(params[:return_to]) || course_group_formation_path(@course)
  end

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:group_id])
  end
end
