require 'test_helper'

class GroupDirectInviterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)

    @recipient = create(:user)
    create(:enrolment, course: @course, user: @recipient, role: :student)
  end

  test 'leader invites an ungrouped enrolled student — pending direct_invite created, mailer queued' do
    assert_enqueued_jobs 1 do
      result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!
      assert result.invited?
    end

    invite = ProjectGroupInvite.find_by(project_group: @group, recipient: @recipient)
    assert invite.present?
    assert invite.direct_invite?
    assert invite.pending?
  end

  test 'blocked when recipient is not enrolled in the course' do
    outsider = create(:user) # no enrolment at all

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: outsider).invite!

    assert result.blocked?
    assert_equal :invalid_recipient, result.blocked_reason
  end

  test 'blocked when recipient is enrolled as a non-student (e.g. lecturer)' do
    lecturer = create(:user)
    create(:enrolment, course: @course, user: lecturer, role: :lecturer)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: lecturer).invite!

    assert result.blocked?
    assert_equal :invalid_recipient, result.blocked_reason
  end

  test 'blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocked when group already confirmed' do
    create_list(:project_group_member, 1, project_group: @group) # bring size to 2 (min)
    @group.update!(confirmed: true)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  test 'blocked when group is full' do
    filler = create(:user)
    create(:enrolment, course: @course, user: filler, role: :student)
    create(:project_group_member, project_group: @group, user: filler)
    another = create(:user)
    create(:enrolment, course: @course, user: another, role: :student)
    create(:project_group_member, project_group: @group, user: another)
    # group_max: 3, now at 3 (leader+filler+another)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.blocked?
    assert_equal :group_full, result.blocked_reason
  end

  test 'blocked when recipient is already grouped elsewhere in the course' do
    other_group = create(:project_group, course: @course, leader_id: @recipient.id)
    create(:project_group_member, project_group: other_group, user: @recipient)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'duplicate pending invite to the same recipient+group is rescued into already_invited' do
    GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.blocked?
    assert_equal :already_invited, result.blocked_reason
    assert_equal 1, ProjectGroupInvite.where(project_group: @group, recipient: @recipient).count
  end

  # ── Edge: no locked? check at all — invites bypass lock state by design ───

  test 'inviting works on a locked group — lock status is irrelevant to direct invites' do
    @group.update!(locked: true)

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.invited?
  end

  # ── Edge: leader inviting themselves — implicitly blocked via already_grouped ─

  test 'leader inviting themselves is blocked as already_grouped, not a distinct error' do
    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @leader).invite!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  # ── Edge: same student can hold pending invites from multiple groups at once ─

  test 'a student can hold pending invites from two different groups simultaneously' do
    other_leader = create(:user)
    create(:enrolment, course: @course, user: other_leader, role: :student)
    other_group = create(:project_group, course: @course, leader_id: other_leader.id)
    create(:project_group_member, project_group: other_group, user: other_leader)

    result_a = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!
    result_b = GroupDirectInviter.new(other_group, current_user: other_leader, recipient: @recipient).invite!

    assert result_a.invited?
    assert result_b.invited?
    assert_equal 2, ProjectGroupInvite.where(recipient: @recipient, status: :pending).count
  end

  # ── Contrast with GroupJoiner: nil group_max IS treated as unlimited here ────

  test 'nil group_max is treated as unlimited, not zero capacity' do
    @course.update_columns(group_max: nil) # bypasses course validation to isolate this service's logic

    result = GroupDirectInviter.new(@group, current_user: @leader, recipient: @recipient).invite!

    assert result.invited?
  end
end
