class ProjectGroupMembersController < ApplicationController
  include ActionView::RecordIdentifier

  before_action :set_project_group_member, only: %i[destroy]

  rescue_from ActiveRecord::RecordNotFound do
    redirect_back fallback_location: root_path, alert: 'This member has already been removed.'
  end

  def destroy
    authorize @project_group_member

    removed_student = @project_group_member.user
    member_dom_id = dom_id(@project_group_member)
    group_dom_id = dom_id(@project_group_member.project_group)

    result = GroupMemberRemover.new(
      @project_group_member,
      current_user: current_user,
      dissolve_confirmed: params[:dissolve_confirmed] == 'true'
    ).remove!

    if result.needs_confirmation?
      render turbo_stream: turbo_stream.append(
        'modals',
        partial: 'project_group_members/dissolve_warning_modal',
        locals: { member: @project_group_member, result: result }
      )
      return
    end

    respond_to do |format|
      format.turbo_stream do
        if result.blocked?
          render turbo_stream: turbo_stream.remove('dissolve-warning-modal')
        else
          removed_node = result.dissolved? ? group_dom_id : member_dom_id
          render turbo_stream: [
            turbo_stream.remove(removed_node),
            turbo_stream.append('ungrouped-students-list',
                                partial: 'project_groups/ungrouped_student',
                                locals: { student: removed_student }),
            turbo_stream.remove('dissolve-warning-modal')
          ]
        end
      end
      format.html do
        redirect_back fallback_location: root_path,
                      **(result.blocked? ? { alert: result.message } : { notice: result.message })
      end
    end
  end

  private

  def set_project_group_member
    @project_group_member = ProjectGroupMember.find(params[:id])
  end
end
