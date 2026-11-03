require 'test_helper'

module Groups
  class ApprovalTogglerTest < ActiveSupport::TestCase
    setup do
      @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
      @leader = create(:user)
      @group = create(:project_group, course: @course, leader_id: @leader.id)
      create(:project_group_member, project_group: @group, user: @leader)
    end

    test 'locks and unlocks the group while formation is open' do
      result = ApprovalToggler.new(@group, locked: true).set!
      assert result.updated?
      assert @group.reload.locked?

      result = ApprovalToggler.new(@group, locked: false).set!
      assert result.updated?
      assert_not @group.reload.locked?
    end

    test 'unlocking does not need a leader' do
      @group.update!(leader_id: nil)

      result = ApprovalToggler.new(@group, locked: false).set!

      assert result.updated?
      assert_not @group.reload.locked?
    end

    test 'blocks locking without a leader' do
      @group.update!(leader_id: nil)

      result = ApprovalToggler.new(@group, locked: true).set!

      assert result.blocked?
      assert_equal :no_leader, result.blocked_reason
    end

    test 'blocks when the group is confirmed' do
      @group.update!(confirmed: true)

      result = ApprovalToggler.new(@group, locked: true).set!

      assert result.blocked?
      assert_equal :group_confirmed, result.blocked_reason
    end

    test 'blocks when formation is closed' do
      @course.update!(grouping_open: false)

      result = ApprovalToggler.new(@group, locked: true).set!

      assert result.blocked?
      assert_equal :window_closed, result.blocked_reason
    end
  end
end
