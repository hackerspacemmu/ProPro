require 'test_helper'

class GroupInviteLinkRedeemerTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)

    @link_sender = create(:user)
    create(:enrolment, course: @course, user: @link_sender, role: :student)
    @link = create(:project_group_invite_link, project_group: @group, sender: @link_sender,
                                               token: 'valid-token', expires_at: 1.hour.from_now)

    @redeemer_user = create(:user)
    create(:enrolment, course: @course, user: @redeemer_user, role: :student)
  end

  test 'valid unexpired link grants instant membership, no approval step' do
    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.redeemed?
    assert_equal @group.id, result.group.id
    assert @group.project_group_members.exists?(user_id: @redeemer_user.id)
  end

  test 'blocked when link has expired' do
    @link.update!(expires_at: 1.hour.ago)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :expired, result.blocked_reason
  end

  test 'blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocked when group already confirmed' do
    create(:project_group_member, project_group: @group)
    @group.update!(confirmed: true)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  test 'blocked when group is full' do
    2.times do
      filler = create(:user)
      create(:enrolment, course: @course, user: filler, role: :student)
      create(:project_group_member, project_group: @group, user: filler)
    end
    # group_max: 3, now at 3 (leader + 2 fillers)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :group_full, result.blocked_reason
  end

  test 'blocked when redeemer is already grouped elsewhere in the course' do
    other_group = create(:project_group, course: @course, leader_id: @redeemer_user.id)
    create(:project_group_member, project_group: other_group, user: @redeemer_user)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  # ── Edge: redemption bypasses locked? entirely — a link joins a locked group ──

  test 'redeeming a link joins a LOCKED group instantly, bypassing the request/approve flow' do
    @group.update!(locked: true)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.redeemed?, 'confirm intentional: link redemption ignores locked? entirely'
  end

  # ── Edge: clears BOTH sender-role and recipient-role pending invites course-wide ─

  test 'redeeming clears the redeemer\'s own pending request (sender role) course-wide' do
    other_group = create(:project_group, course: @course, leader_id: @leader.id)
    own_request = create(:project_group_invite, project_group: other_group, sender: @redeemer_user,
                                                recipient: @leader, kind: :direct_request, status: :pending)

    GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert_not ProjectGroupInvite.exists?(own_request.id)
  end

  test 'redeeming clears a pending direct_invite where the redeemer is the RECIPIENT' do
    other_group = create(:project_group, course: @course, leader_id: @leader.id)
    incoming_invite = create(:project_group_invite, project_group: other_group, sender: @leader,
                                                    recipient: @redeemer_user, kind: :direct_invite, status: :pending)

    GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert_not ProjectGroupInvite.exists?(incoming_invite.id)
  end

  test 'redeeming does not touch an unrelated user\'s pending invite' do
    other_student = create(:user)
    create(:enrolment, course: @course, user: other_student, role: :student)
    unrelated = create(:project_group_invite, project_group: @group, sender: other_student,
                                              recipient: @leader, kind: :direct_request, status: :pending)

    GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert ProjectGroupInvite.exists?(unrelated.id)
  end

  # ── Edge: exact expiry boundary ────────────────────────────────────────────

  test 'link is still redeemable at the exact instant of expires_at (not-yet-past)' do
    travel_to @link.expires_at do
      result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!
      assert result.redeemed?
    end
  end

  test 'link is blocked one second past expires_at' do
    travel_to @link.expires_at + 1.second do
      result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!
      assert result.blocked?
      assert_equal :expired, result.blocked_reason
    end
  end
end
