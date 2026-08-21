require 'test_helper'

class GroupInviteLinkGeneratorTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                             group_min: 2, group_max: 4, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)
  end

  test 'leader generates a link — created with a token and 24h expiry' do
    result = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert result.generated?
    assert result.token.present?
    assert_in_delta 24.hours.from_now, result.expires_at, 5.seconds

    link = @group.project_group_invite_links.find_by(sender: @leader)
    assert_equal result.token, link.token
  end

  test 'regenerating destroys this sender\'s old link and creates a new one' do
    first = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!
    second = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert_not_equal first.token, second.token
    assert_equal 1, @group.project_group_invite_links.where(sender: @leader).count
    assert_not ProjectGroupInviteLink.exists?(token: first.token)
  end

  test 'regenerating does not touch another sender\'s link' do
    other_member = create(:user)
    create(:enrolment, course: @course, user: other_member, role: :student)
    create(:project_group_member, project_group: @group, user: other_member)
    other_link = GroupInviteLinkGenerator.new(@group, current_user: other_member).generate!

    GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert ProjectGroupInviteLink.exists?(token: other_link.token)
  end

  test 'blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocked when group already confirmed' do
    create(:project_group_member, project_group: @group)
    @group.update!(confirmed: true)

    result = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  # ── Edge: leadership transfer doesn't revoke the ex-leader's existing link ────

  test 'a link generated before a leadership transfer stays fully valid after the transfer' do
    old_leader_link = GroupInviteLinkGenerator.new(@group, current_user: @leader).generate!

    new_leader = create(:user)
    create(:enrolment, course: @course, user: new_leader, role: :student)
    create(:project_group_member, project_group: @group, user: new_leader)
    @group.update!(leader_id: new_leader.id) # simulates promote_next_leader!/promote_leader

    assert ProjectGroupInviteLink.exists?(token: old_leader_link.token)
    link = ProjectGroupInviteLink.find_by(token: old_leader_link.token)
    assert_not link.expires_at.past?
  end
end