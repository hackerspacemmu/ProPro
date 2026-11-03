require 'test_helper'

module Groups
  class LeaderPromoterTest < ActiveSupport::TestCase
    setup do
      @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
      @leader = create(:user)
      @member = create(:user)
      @outsider = create(:user)
      @group = create(:project_group, course: @course, leader_id: @leader.id)
      create(:project_group_member, project_group: @group, user: @leader)
      create(:project_group_member, project_group: @group, user: @member)
    end

    test 'promotes a member while formation is open' do
      result = LeaderPromoter.new(@group, target_user_id: @member.id).promote!

      assert result.promoted?
      assert_equal @member.id, @group.reload.leader_id
    end

    test 'blocks a non-member' do
      result = LeaderPromoter.new(@group, target_user_id: @outsider.id).promote!

      assert result.blocked?
      assert_equal :not_a_member, result.blocked_reason
      assert_equal @leader.id, @group.reload.leader_id
    end

    test 'blocks when the group is confirmed' do
      @group.update!(confirmed: true)

      result = LeaderPromoter.new(@group, target_user_id: @member.id).promote!

      assert result.blocked?
      assert_equal :group_confirmed, result.blocked_reason
    end

    test 'blocks when formation is closed' do
      @course.update!(grouping_open: false)

      result = LeaderPromoter.new(@group, target_user_id: @member.id).promote!

      assert result.blocked?
      assert_equal :window_closed, result.blocked_reason
    end
  end
end
