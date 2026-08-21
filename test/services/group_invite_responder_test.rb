require 'test_helper'

class GroupInviteResponderTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id, locked: true)
    create(:project_group_member, project_group: @group, user: @leader)

    @student = create(:user)
    create(:enrolment, course: @course, user: @student, role: :student)
  end

  # ── direct_request: student sent it, leader is recipient ─────────────────

  test 'leader accepts a direct_request — sender (the requesting student) is added as member' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.accepted?
    assert @group.project_group_members.exists?(user_id: @student.id)
    assert invite.reload.accepted?
  end

  # ── direct_invite: leader sent it, student is recipient ──────────────────

  test 'student accepts a direct_invite — recipient (the invited student) is added as member' do
    invite = create(:project_group_invite, project_group: @group, sender: @leader, recipient: @student,
                                           kind: :direct_invite, status: :pending)

    result = GroupInviteResponder.new(invite, current_user: @student).accept!

    assert result.accepted?
    assert @group.project_group_members.exists?(user_id: @student.id)
    assert invite.reload.accepted?
  end

  test 'declining either kind flips status without changing membership' do
    request = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                            kind: :direct_request, status: :pending)
    invite  = create(:project_group_invite, project_group: @group, sender: @leader, recipient: @student,
                                            kind: :direct_invite, status: :pending)

    GroupInviteResponder.new(request, current_user: @leader).decline!
    GroupInviteResponder.new(invite, current_user: @student).decline!

    assert request.reload.declined?
    assert invite.reload.declined?
    assert_not @group.project_group_members.exists?(user_id: @student.id)
  end

  test 'accept blocked with already_responded when invite was already handled' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :accepted)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :already_responded, result.blocked_reason
  end

  test 'accept blocked when window closed' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    @course.update!(grouping_open: false)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'accept blocked when joining user is already grouped elsewhere' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    other_group = create(:project_group, course: @course, leader_id: @student.id)
    create(:project_group_member, project_group: other_group, user: @student)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'accept blocked when group already confirmed' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    create(:project_group_member, project_group: @group)
    @group.update!(confirmed: true)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  test 'accept blocked when group is full' do
    2.times do
      filler = create(:user)
      create(:enrolment, course: @course, user: filler, role: :student)
      create(:project_group_member, project_group: @group, user: filler)
    end
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :group_full, result.blocked_reason
  end

  test 'decline blocked with already_responded when invite was already handled' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :declined)

    result = GroupInviteResponder.new(invite, current_user: @leader).decline!

    assert result.blocked?
    assert_equal :already_responded, result.blocked_reason
  end

  # ── Edge: accept! reloads inside the lock — double-accept race is caught ─────

  test 'concurrent double-accept — only one actually adds the member' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)

    results = Array.new(2) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          GroupInviteResponder.new(ProjectGroupInvite.find(invite.id), current_user: @leader).accept!
        end
      end
    end.map(&:value)

    accepted = results.select(&:accepted?)
    blocked  = results.select(&:blocked?)

    assert_equal 1, accepted.length
    assert_equal 1, blocked.length
    assert_equal :already_responded, blocked.first.blocked_reason
    assert_equal 1, @group.project_group_members.where(user_id: @student.id).count
  end

  # ── Edge: decline! has no with_lock, no window/confirmed gate at all ─────────

  test 'declining is allowed even after the grouping window has closed' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    @course.update!(grouping_open: false)

    result = GroupInviteResponder.new(invite, current_user: @leader).decline!

    assert result.declined?
  end

  test 'declining is allowed even after the group has been confirmed' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    create(:project_group_member, project_group: @group)
    @group.update!(confirmed: true)

    result = GroupInviteResponder.new(invite, current_user: @leader).decline!

    assert result.declined?
  end

  # ── Edge: accepting clears the joining user's OTHER pending items, not this one ─

  test 'accepting clears the joining user\'s other pending invites, and does not touch the one just accepted' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    other_group = create(:project_group, course: @course, leader_id: @leader.id)
    stale_request = create(:project_group_invite, project_group: other_group, sender: @student,
                                                  recipient: @leader, kind: :direct_request, status: :pending)

    GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert invite.reload.accepted?, 'the invite being accepted must survive clear_conflicting_invites!'
    assert_not ProjectGroupInvite.exists?(stale_request.id)
  end
end
