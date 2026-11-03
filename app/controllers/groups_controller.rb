# Handles Groups Tab
class GroupsController < ApplicationController
  include ParticipantBrowsing
  include CoursesHelper

  before_action :set_course
  before_action :authorize_course, only: %i[index show]
  before_action :ensure_grouped, only: %i[index show]
  before_action :set_group, only: %i[show edit update destroy]

  def index
    projects = @course.projects.includes(project_instances: { supervisor_enrolment: :user }).load
    @projects_by_owner = projects.index_by { |p| [p.owner_type, p.owner_id] }

    @group_list = @course.project_groups.includes(project_group_members: :user).to_a

    @filtered_group_list = filtered_group_list
    @show_all = params[:show_all] == 'true'
    @total_group_count = @filtered_group_list.count
    @filtered_group_list = @filtered_group_list.first(Rails.application.config.participants_pagination_threshold) unless @show_all

    @group_list_state = list_state(@group_list, @filtered_group_list)
    @filters_active = filters_active?(PARTICIPANT_FILTER_KEYS)

    return unless request.headers['HX-Request']

    render partial: 'courses/groups_table',
           locals: {
             course: @course,
             groups: @filtered_group_list,
             projects_by_owner: @projects_by_owner,
             total_count: @total_group_count,
             displayed_count: @filtered_group_list.count,
             show_all: @show_all,
             state: @group_list_state,
             filters_active: @filters_active
           }
    nil
  end

  def show
    projects = @course.projects.includes(project_instances: { supervisor_enrolment: :user }).load
    @projects_by_owner = projects.index_by { |p| [p.owner_type, p.owner_id] }

    @members = @group.project_group_members.includes(:user)
    @project = group_project_for(@group, @projects_by_owner)
    @status = group_status(@group, @projects_by_owner)
    @current_instance = @project&.current_instance
    @supervisor = @project&.supervisor if @project
  end

  def edit
    authorize @group, :edit?

    @incoming_join_requests = @group.project_group_invites.pending_for_group(@group).where(kind: :direct_request)
    @my_group_invite_token = @group.project_group_invite_links.find_by(sender: current_user)&.token
    @my_invited_student_ids = ProjectGroupInvite.for_course(@course).sent_by(current_user).pending.where(kind: :direct_invite).pluck(:recipient_id)
    @ungrouped_students = ungrouped_students
  end

  def create
    @group = @course.project_groups.build
    authorize @group, :create?

    leader = policy(@course).manage_groups? ? @course.students.find(params.expect(:user_id)) : current_user
    result = GroupCreator.new(@course, leader: leader, current_user: current_user).create!

    if result.created?
      redirect_to course_group_formation_path(@course), notice: result.message
    else
      redirect_to course_group_formation_path(@course), alert: result.message
    end
  end

  def update
    authorize @group, :update?

    attrs = params.expect(project_group: [:locked])
    locked = ActiveModel::Type::Boolean.new.cast(attrs[:locked])
    result = update_approval(locked)

    redirect_to course_group_formation_path(@course),
                **(result.blocked? ? { alert: result.message } : { notice: result.message })
  end

  def destroy
    authorize @group, :destroy?

    result = delete_group

    if result.needs_confirmation?
      render turbo_stream: turbo_stream.append(
        'modals',
        partial: 'groups/delete_warning_modal',
        locals: { group: @group, result: result }
      )
      return
    end

    redirect_to course_group_formation_path(@course), notice: result.message
  end

  private

  def update_approval(locked)
    if coordinator?
      Groups::Coordinator::ApprovalToggler.new(@group, locked: locked).set!
    else
      Groups::ApprovalToggler.new(@group, locked: locked).set!
    end
  end

  def delete_group
    if coordinator?
      Groups::Coordinator::GroupDeleter.new(@group, confirm: params[:confirm] == 'true').delete!
    else
      Groups::Deleter.new(@group).delete!
    end
  end

  def coordinator?
    @course.enrolments.exists?(user_id: current_user.id, role: :coordinator)
  end

  def set_course
    @course = Course.find(params[:course_id])
    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
  end

  def authorize_course
    authorize @course, :show?
  end

  def ensure_grouped
    raise ActiveRecord::RecordNotFound unless @course.grouped?
  end

  def set_group
    @group = @course.project_groups.find(params[:id])
  end

  def ungrouped_students
    enrolled_student_ids = @course.enrolments.where(role: :student).pluck(:user_id)
    grouped_student_ids = ProjectGroupMember.joins(:project_group)
                                            .where(project_groups: { course_id: @course.id })
                                            .pluck(:user_id)
    User.where(id: enrolled_student_ids - grouped_student_ids).order(:name)
  end
end
