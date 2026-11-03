require 'test_helper'

module Groups
  module Coordinator
    class ApprovalTogglerTest < ActiveSupport::TestCase
      setup do
        @course = create(:course, :grouped, grouping_enabled: true, grouping_open: false, group_min: 2, group_max: 4)
        @leader = create(:user)
        @group = create(:project_group, course: @course, leader_id: @leader.id, confirmed: true)
        create(:project_group_member, project_group: @group, user: @leader)
      end

      test 'locks a closed, confirmed group' do
        result = ApprovalToggler.new(@group, locked: true).set!

        assert result.updated?
        assert @group.reload.locked?
      end

      test 'blocks locking without a leader' do
        @group.update!(leader_id: nil)

        result = ApprovalToggler.new(@group, locked: true).set!

        assert result.blocked?
        assert_equal :no_leader, result.blocked_reason
      end
    end
  end
end
