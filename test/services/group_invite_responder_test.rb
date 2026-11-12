require 'test_helper'

class GroupInviteResponderTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @course = create(:course, grouping_enabled: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
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

  test 'accepting enqueues the accepted notification after the group lock' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)

    assert_enqueued_jobs 1 do
      result = GroupInviteResponder.new(invite, current_user: @leader).accept!
      assert result.accepted?
    end
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

  test 'accept blocked when the joining student is no longer enrolled' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    Enrolment.find_by!(user: @student, course: @course).destroy!

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :not_enrolled, result.blocked_reason
    assert invite.reload.pending?
    assert_not @group.project_group_members.exists?(user_id: @student.id)
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

  test 'accept blocked when the pending request is older than 24 hours' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)

    travel_to(25.hours.from_now) do
      result = GroupInviteResponder.new(invite, current_user: @leader).accept!

      assert result.blocked?
      assert_equal :expired, result.blocked_reason
      assert invite.reload.pending?
      assert_not @group.project_group_members.exists?(user_id: @student.id)
    end
  end

  test 'accept is not blocked by age for a direct invite' do
    invite = create(:project_group_invite, project_group: @group, sender: @leader, recipient: @student,
                                           kind: :direct_invite, status: :pending)

    travel_to(25.hours.from_now) do
      result = GroupInviteResponder.new(invite, current_user: @student).accept!

      assert result.accepted?
    end
  end

  test 'accept blocked when window closed' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    @course.update!(grouping_closes_at: 1.hour.ago)

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

  test 'accepting a request into a confirmed group reopens it' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    @group.update!(confirmed: true, group_name: 'G001')

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.accepted?
    assert result.reopened?
    assert_not @group.reload.confirmed?
    assert_equal 'Tmp001', @group.group_name
    assert @group.project_group_members.exists?(user_id: @student.id)
    assert invite.reload.accepted?
  end

  test 'accepting an invite into a confirmed group reopens it too' do
    invite = create(:project_group_invite, project_group: @group, sender: @leader, recipient: @student,
                                           kind: :direct_invite, status: :pending)
    @group.update!(confirmed: true)

    result = GroupInviteResponder.new(invite, current_user: @student).accept!

    assert result.accepted?
    assert result.reopened?
    assert_not @group.reload.confirmed?
    assert @group.project_group_members.exists?(user_id: @student.id)
  end

  test 'reopening a confirmed group queues the accepted mail plus one notification per member' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    @group.update!(confirmed: true)

    assert_enqueued_jobs 3 do
      result = GroupInviteResponder.new(invite, current_user: @leader).accept!

      assert result.accepted?
      assert result.reopened?
    end
  end

  test 'accepting into a not-confirmed group sends no reopened notification' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)

    assert_enqueued_jobs 1 do
      result = GroupInviteResponder.new(invite, current_user: @leader).accept!

      assert result.accepted?
      assert_not result.reopened?
    end
  end

  test 'accept blocked when the group has a project' do
    @group.update!(confirmed: true)
    supervisor = create(:enrolment, :lecturer, course: @course)
    Project.create!(course: @course, owner: @group, supervisor_enrolment: supervisor)
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :has_project, result.blocked_reason
    assert invite.reload.pending?
    assert_not @group.project_group_members.exists?(user_id: @student.id)
  end

  test 'accept blocked for an imported group' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    @group.update!(confirmed: true, origin: :import)

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :imported_group, result.blocked_reason
  end

  test 'accept blocked when the request was cleared before it was handled' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    ProjectGroupInvite.where(id: invite.id).delete_all

    result = GroupInviteResponder.new(invite, current_user: @leader).accept!

    assert result.blocked?
    assert_equal :invite_gone, result.blocked_reason
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

  # ── Edge: decline! has no with_lock, no window/confirmed gate at all ─────────

  test 'declining is allowed even after the grouping window has closed' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    @course.update!(grouping_closes_at: 1.hour.ago)

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

class GroupInviteResponderRaceTest < NonTransactionalTestCase
  setup do
    @course = create(:course, grouping_enabled: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)

    @student = create(:user)
    create(:enrolment, course: @course, user: @student, role: :student)
  end

  test 'concurrent double-accept — only one actually adds the member' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)

    release = Queue.new
    holder = hold_group_lock(release)
    start = Queue.new

    threads = Array.new(2) do
      Thread.new do
        with_connection do
          start.pop
          GroupInviteResponder.new(ProjectGroupInvite.find(invite.id), current_user: @leader).accept!
        end
      end
    end

    2.times { start << true }
    wait_for_lock_waits(2)
    release << true

    results = Timeout.timeout(10) { threads.map(&:value) }
    accepted = results.select(&:accepted?)
    blocked  = results.select(&:blocked?)

    assert_equal 1, accepted.length
    assert_equal 1, blocked.length
    assert_equal :already_responded, blocked.first.blocked_reason
    assert_equal 1, @group.project_group_members.where(user_id: @student.id).count
  ensure
    release << true if release
    (threads || []).each { |thread| thread.join(1) || thread.kill }
    holder&.join(1)
    holder&.kill
  end

  test 'an accept waiting on the group lock does not add a student removed from the course' do
    invite = create(:project_group_invite, project_group: @group, sender: @student, recipient: @leader,
                                           kind: :direct_request, status: :pending)
    release = Queue.new
    holder = hold_group_lock(release)
    thread = nil

    thread = Thread.new do
      with_connection do
        GroupInviteResponder.new(ProjectGroupInvite.find(invite.id), current_user: @leader).accept!
      end
    end

    wait_for_lock_wait
    Enrolment.find_by!(user: @student, course: @course).destroy!
    release << true

    result = Timeout.timeout(10) { thread.value }

    assert result.blocked?
    assert_equal :not_enrolled, result.blocked_reason
    assert invite.reload.pending?
    assert_not @group.project_group_members.exists?(user_id: @student.id)
  ensure
    release << true if release
    thread&.join(1) || thread&.kill
    holder&.join(1)
    holder&.kill
  end

  private

  def hold_group_lock(release)
    held = Queue.new

    thread = Thread.new do
      with_connection do
        ProjectGroup.transaction do
          ProjectGroup.lock.find(@group.id)
          held << true
          release.pop
        end
      end
    end

    held.pop
    thread
  end
end
