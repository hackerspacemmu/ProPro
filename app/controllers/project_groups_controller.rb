class ProjectGroupsController < ApplicationController
  before_action :set_course
  before_action :set_group, only: %i[destroy confirm revert lock unlock promote_leader]

  def index
    authorize @course, :grouping?
    @current_user_enrolment = @course.enrolments.find_by(user: current_user)
    @my_group = @course.project_groups
                       .includes(project_group_members: :user)
                       .joins(:project_group_members)
                       .find_by(project_group_members: { user_id: current_user.id })
                       
    @groups = @course.project_groups
                     .includes(project_group_members: :user)
                     .order(:created_at)
    enrolled_student_ids = @course.enrolments.where(role: :student).pluck(:user_id)
    grouped_student_ids  = ProjectGroupMember.joins(:project_group)
                                             .where(project_groups: { course_id: @course.id })
                                             .pluck(:user_id)
    ungrouped_ids        = enrolled_student_ids - grouped_student_ids
    @ungrouped_students  = User.where(id: ungrouped_ids).order(:name)
  end

  def create
    @group = @course.project_groups.build(leader_id: current_user.id)
    authorize @group

    begin
      ActiveRecord::Base.transaction do
        @course.with_lock do
          next_seq = @course.project_groups.maximum(:course_group_sequence).to_i + 1
          @group.course_group_sequence = next_seq
          @group.group_name = format("G%03d", next_seq)
          @group.save!
        end
        ProjectGroupMember.create!(user: current_user, project_group: @group)
      end
    rescue StandardError => e
      redirect_to course_project_groups_path(@course), alert: e.message
      return
    end

    redirect_to course_project_groups_path(@course), notice: "Draft group #{@group.group_name} created."
  end

  def destroy
    authorize @group
    begin
      ActiveRecord::Base.transaction do
        @group.destroy!
      end
    rescue StandardError => e
      redirect_to course_project_groups_path(@course), alert: e.message
      return
    end
    redirect_to course_project_groups_path(@course), notice: 'Group dissolved.'
  end

  def confirm
    authorize @group
    begin
      ActiveRecord::Base.transaction do
        raise StandardError, 'This group cannot be confirmed yet.' unless @group.confirm!
      end
    rescue StandardError => e
      redirect_to course_project_groups_path(@course), alert: e.message
      return
    end
    redirect_to course_project_groups_path(@course), notice: "#{@group.group_name} confirmed."
  end

  def revert
    authorize @group
    begin
      ActiveRecord::Base.transaction do
        @group.revert_to_draft!
      end
    rescue StandardError => e
      redirect_to course_project_groups_path(@course), alert: e.message
      return
    end
    redirect_to course_project_groups_path(@course), notice: "#{@group.group_name} reverted to draft."
  end

  def lock
    authorize @group
    begin
      @group.update!(locked: true)
    rescue StandardError => e
      redirect_to course_project_groups_path(@course), alert: e.message
      return
    end
    redirect_to course_project_groups_path(@course), notice: 'Group is now locked.'
  end

  def unlock
    authorize @group
    begin
      @group.update!(locked: false)
    rescue StandardError => e
      redirect_to course_project_groups_path(@course), alert: e.message
      return
    end
    redirect_to course_project_groups_path(@course), notice: 'Group is now open to join.'
  end

  def promote_leader
    authorize @group
    target_member = @group.project_group_members.find_by!(user_id: params[:user_id])
    begin
      @group.update!(leader_id: target_member.user_id)
    rescue StandardError => e
      redirect_to course_project_groups_path(@course), alert: e.message
      return
    end
    redirect_to course_project_groups_path(@course), notice: "#{target_member.user.name} is now the group leader."
  end

  def coordinator_actions
    authorize @course, :grouping_coordinator?
    @groups = @course.project_groups.includes(project_group_members: :user)

    enrolled_student_ids = @course.enrolments.where(role: :student).pluck(:user_id)
    grouped_student_ids  = ProjectGroupMember.joins(:project_group)
                                             .where(project_groups: { course_id: @course.id })
                                             .pluck(:user_id)
    ungrouped_ids        = enrolled_student_ids - grouped_student_ids

    @ungrouped_students = User.where(id: ungrouped_ids).order(:name)
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_group
    @group = @course.project_groups.find(params[:id])
  end
end
