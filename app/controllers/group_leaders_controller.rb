class GroupLeadersController < ApplicationController
  before_action :set_course
  before_action :set_group

  def update
    authorize @group, :promote_leader?

    result = promote_leader

    redirect_to course_group_formation_path(@course),
                **(result.blocked? ? { alert: result.message } : { notice: result.message })
  end

  private

  def promote_leader
    target_user_id = params.expect(:user_id)

    if coordinator?
      Groups::Coordinator::LeaderPromoter.new(@group, target_user_id: target_user_id).promote!
    else
      Groups::LeaderPromoter.new(@group, target_user_id: target_user_id).promote!
    end
  end

  def coordinator?
    @course.enrolments.exists?(user_id: current_user.id, role: :coordinator)
  end

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:group_id])
  end
end
