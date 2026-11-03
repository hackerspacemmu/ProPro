require 'test_helper'

module Groups
  class KickerTest < ActiveSupport::TestCase
    setup do
      @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
      @leader = create(:user)
      @member = create(:user)
      @other = create(:user)
      @group = create(:project_group, course: @course, leader_id: @leader.id)
      create(:project_group_member, project_group: @group, user: @leader)
      @membership = create(:project_group_member, project_group: @group, user: @member)
      create(:project_group_member, project_group: @group, user: @other)
    end

    test 'the leader can remove another member' do
      result = Kicker.new(@membership, current_user: @leader).kick!

      assert result.removed?
      assert_not @group.project_group_members.exists?(user: @member)
      assert_equal @leader.id, @group.reload.leader_id
    end

    test 'a non-leader cannot remove a member' do
      result = Kicker.new(@membership, current_user: @other).kick!

      assert result.blocked?
      assert_equal :not_leader, result.blocked_reason
      assert @group.project_group_members.exists?(user: @member)
    end

    test 'the leader cannot remove themselves' do
      membership = @group.project_group_members.find_by!(user: @leader)

      result = Kicker.new(membership, current_user: @leader).kick!

      assert result.blocked?
      assert_equal :self_kick, result.blocked_reason
    end

    test 'blocks a member who was already removed' do
      @membership.destroy!

      result = Kicker.new(@membership, current_user: @leader).kick!

      assert result.blocked?
      assert_equal :already_removed, result.blocked_reason
    end

    test 'blocks when the group is confirmed' do
      @group.update!(confirmed: true)

      result = Kicker.new(@membership, current_user: @leader).kick!

      assert result.blocked?
      assert_equal :group_confirmed, result.blocked_reason
    end

    test 'blocks when formation is closed' do
      @course.update!(grouping_open: false)

      result = Kicker.new(@membership, current_user: @leader).kick!

      assert result.blocked?
      assert_equal :window_closed, result.blocked_reason
    end
  end
end
