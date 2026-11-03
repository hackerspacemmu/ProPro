require 'test_helper'

module Groups
  class LeaverTest < ActiveSupport::TestCase
    setup do
      @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
      @leader = create(:user)
      @member = create(:user)
      @group = create(:project_group, course: @course, leader_id: @leader.id)
      @leader_membership = create(:project_group_member, project_group: @group, user: @leader)
      @membership = create(:project_group_member, project_group: @group, user: @member)
    end

    test 'a member can leave a not-confirmed group' do
      result = Leaver.new(@membership).leave!

      assert result.removed?
      assert_not @group.project_group_members.exists?(user: @member)
      assert_equal @leader.id, @group.reload.leader_id
    end

    test 'the leader is replaced by the earliest remaining member' do
      other = create(:user)
      other_membership = create(:project_group_member, project_group: @group, user: other)
      earliest = Time.zone.parse('2024-01-01 10:00:00')
      @membership.update_columns(created_at: earliest)
      other_membership.update_columns(created_at: earliest)

      result = Leaver.new(@leader_membership).leave!

      assert result.removed?
      assert_equal @member.id, @group.reload.leader_id
    end

    test 'the last member deletes the group' do
      @membership.destroy!

      result = Leaver.new(@leader_membership).leave!

      assert result.group_deleted?
      assert_not ProjectGroup.exists?(@group.id)
    end

    test 'blocks when the group is confirmed' do
      @group.update!(confirmed: true)

      result = Leaver.new(@membership).leave!

      assert result.blocked?
      assert_equal :group_confirmed, result.blocked_reason
      assert @group.project_group_members.exists?(user: @member)
    end

    test 'blocks when formation is closed' do
      @course.update!(grouping_open: false)

      result = Leaver.new(@membership).leave!

      assert result.blocked?
      assert_equal :window_closed, result.blocked_reason
    end

    test 'refuses whenever the group owns a proposal' do
      @group.update!(confirmed: true)
      create(:project, course: @course, owner: @group, owner_type: 'ProjectGroup',
                       supervisor_enrolment: create(:enrolment, :lecturer, course: @course))
      @group.update_columns(confirmed: false)

      result = Leaver.new(@membership).leave!

      assert result.blocked?
      assert_equal :has_project, result.blocked_reason
      assert @group.project_group_members.exists?(user: @member)
    end

    test 'blocks a member who was already removed' do
      @membership.destroy!

      result = Leaver.new(@membership).leave!

      assert result.blocked?
      assert_equal :already_removed, result.blocked_reason
    end
  end
end
