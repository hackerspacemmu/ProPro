require 'test_helper'

module Groups
  module Coordinator
    class LeaderPromoterTest < ActiveSupport::TestCase
      setup do
        @course = create(:course, :grouped, grouping_enabled: true, grouping_open: false, group_min: 2, group_max: 4)
        @leader = create(:user)
        @member = create(:user)
        @group = create(:project_group, course: @course, leader_id: @leader.id, confirmed: true)
        create(:project_group_member, project_group: @group, user: @leader)
        create(:project_group_member, project_group: @group, user: @member)
      end

      test 'promotes a member in a closed, confirmed group' do
        result = LeaderPromoter.new(@group, target_user_id: @member.id).promote!

        assert result.promoted?
        assert_equal @member.id, @group.reload.leader_id
      end

      test 'blocks a non-member' do
        result = LeaderPromoter.new(@group, target_user_id: create(:user).id).promote!

        assert result.blocked?
        assert_equal :not_a_member, result.blocked_reason
      end
    end
  end
end
