require 'test_helper'

module Groups
  class InviteLinkDisablerTest < ActiveSupport::TestCase
    setup do
      @course = create(:course, :grouped, group_formation_enabled: true, group_min: 2, group_max: 4)
      @leader = create(:user)
      @group = create(:project_group, course: @course, leader_id: @leader.id)
      create(:project_group_member, project_group: @group, user: @leader)
      @link = create(:project_group_invite_link, project_group: @group, sender: @leader)
    end

    test 'deletes every link of the group' do
      other = create(:project_group_invite_link, project_group: @group, sender: @leader)

      result = InviteLinkDisabler.new(@group).disable!

      assert result.disabled?
      assert_equal 'Invite link disabled.', result.message
      assert_not ProjectGroupInviteLink.exists?(@link.id)
      assert_not ProjectGroupInviteLink.exists?(other.id)
    end

    test 'is idempotent' do
      InviteLinkDisabler.new(@group).disable!

      result = InviteLinkDisabler.new(@group).disable!

      assert result.disabled?
    end

    test 'blocks when formation is closed' do
      @course.update!(group_formation_closes_at: 1.hour.ago)

      result = InviteLinkDisabler.new(@group).disable!

      assert result.blocked?
      assert_equal :formation_closed, result.blocked_reason
      assert ProjectGroupInviteLink.exists?(@link.id)
    end

    test 'blocks when the group no longer exists' do
      ProjectGroup.find(@group.id).destroy!

      result = InviteLinkDisabler.new(@group).disable!

      assert result.blocked?
      assert_equal :group_gone, result.blocked_reason
    end
  end
end
