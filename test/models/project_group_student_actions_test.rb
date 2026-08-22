require 'test_helper'

class ProjectGroupStudentActionsTest < ActiveSupport::TestCase
  def setup
    @course = create(:course,
                     grouping_enabled: true,
                     student_list_finalised: false,
                     group_min: 2,
                     group_max: 4,
                     grouping_open: true)
    @alice = create(:user)
    @bob   = create(:user)
    @carol = create(:user)

    @group = create(:project_group, course: @course, leader_id: @alice.id)
    create(:project_group_member, project_group: @group, user: @alice,
                                  created_at: 1.hour.ago)
    create(:project_group_member, project_group: @group, user: @bob,
                                  created_at: 30.minutes.ago)
  end

  # ── GroupConfirmer ───────────────────────────────────────────────────────

  test 'GroupConfirmer confirms a legal group' do
    # group has alice + bob (2 members), min is 2
    result = GroupConfirmer.new(@group).confirm!
    assert result.confirmed?
    assert @group.reload.confirmed?
  end

  test 'GroupConfirmer blocks with size_illegal when group is below min' do
    solo = create(:project_group, course: @course, leader_id: @carol.id)
    create(:project_group_member, project_group: solo, user: @carol)
    # only 1 member, min is 2
    result = GroupConfirmer.new(solo).confirm!
    assert_not result.confirmed?
    assert_equal :size_illegal, result.blocked_reason
    assert_not solo.reload.confirmed?
  end

  # ── pending_requests ──────────────────────────────────────────────────────

  test 'pending_requests returns only pending request invites' do
    pending  = create(:project_group_invite, project_group: @group, sender: @carol, status: :pending)
    declined = create(:project_group_invite, project_group: @group, sender: create(:user), status: :declined)

    assert_includes     @group.pending_requests, pending
    assert_not_includes @group.pending_requests, declined
  end

  # ── leader? helper ────────────────────────────────────────────────────────

  test 'leader? returns true for group leader' do
    assert @group.leader?(@alice)
    assert_not @group.leader?(@bob)
  end
end
