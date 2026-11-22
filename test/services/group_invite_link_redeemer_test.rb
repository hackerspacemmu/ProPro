require 'test_helper'

class GroupInviteLinkRedeemerTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @course = create(:course, group_formation_enabled: true,
                              group_min: 2, group_max: 3, prevent_leftover_students: false)
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

  test 'valid link is not blocked as full when the course has no size limits' do
    @course.update_columns(group_min: nil, group_max: nil)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.redeemed?
  end

  test 'valid unexpired link grants instant membership, no approval step' do
    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.redeemed?
    assert_equal @group.id, result.group.id
    assert @group.project_group_members.exists?(user_id: @redeemer_user.id)
  end

  test 'blocked when the redeemer is no longer enrolled in the course' do
    Enrolment.find_by!(user: @redeemer_user, course: @course).destroy!

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :not_enrolled, result.blocked_reason
    assert_not @group.project_group_members.exists?(user_id: @redeemer_user.id)
  end

  test 'blocked when link has expired' do
    @link.update!(expires_at: 1.hour.ago)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :expired, result.blocked_reason
  end

  test 'blocked when formation closed' do
    @course.update!(group_formation_closes_at: 1.hour.ago)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :formation_closed, result.blocked_reason
  end

  test 'redeeming a link into a confirmed group reopens it and notifies every member' do
    @group.update!(confirmed: true, group_name: 'G001')

    assert_enqueued_jobs 2 do
      result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

      assert result.redeemed?
      assert result.reopened?
    end

    assert_not @group.reload.confirmed?
    assert_equal 'Tmp001', @group.group_name
    assert @group.project_group_members.exists?(user_id: @redeemer_user.id)
  end

  test 'redeeming a link into a not-confirmed group sends no reopened notification' do
    assert_enqueued_jobs 0 do
      result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

      assert result.redeemed?
      assert_not result.reopened?
    end
  end

  test 'blocked when the group has a project' do
    @group.update!(confirmed: true)
    supervisor = create(:enrolment, :lecturer, course: @course)
    Project.create!(course: @course, owner: @group, supervisor_enrolment: supervisor)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :has_project, result.blocked_reason
    assert_not @group.project_group_members.exists?(user_id: @redeemer_user.id)
  end

  test 'blocked for an imported group' do
    @group.update!(confirmed: true, origin: :import)

    result = GroupInviteLinkRedeemer.new(@link, current_user: @redeemer_user).redeem!

    assert result.blocked?
    assert_equal :imported_group, result.blocked_reason
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

class GroupInviteLinkRedeemerRaceTest < NonTransactionalTestCase
  setup do
    @course = create(:course, group_formation_enabled: true,
                              group_min: 2, group_max: 3, prevent_leftover_students: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)

    filler = create(:user)
    create(:enrolment, course: @course, user: filler, role: :student)
    create(:project_group_member, project_group: @group, user: filler)

    @link = create(:project_group_invite_link, project_group: @group, sender: @leader,
                                               token: 'race-token', expires_at: 1.hour.from_now)
    @contenders = [create(:user), create(:user)]
    @contenders.each { |user| create(:enrolment, course: @course, user: user, role: :student) }
    @redeemer_user = @contenders.first
  end

  test 'a link that expires while the redeemer waits is refused' do
    release = Queue.new
    holder = hold_group_lock(release)
    thread = redeemer_thread(@redeemer_user)

    wait_for_lock_wait
    @link.update_column(:expires_at, 1.hour.ago)
    release << true

    result = Timeout.timeout(10) { thread.value }

    assert result.blocked?
    assert_equal :expired, result.blocked_reason
    assert_not @group.project_group_members.exists?(user_id: @redeemer_user.id)
  ensure
    release << true if release
    thread&.join(1)
    thread&.kill
    holder&.join(1)
    holder&.kill
  end

  test 'a link cleared by a concurrent confirmation is refused' do
    release = Queue.new
    mutation = Queue.new
    holder = hold_group_lock(release) do
      mutation.pop
      # The confirmer's critical section: links die, then the group confirms.
      @group.clear_invite_links!
      @group.update!(confirmed: true, group_name: 'G001')
    end
    thread = redeemer_thread(@redeemer_user)

    wait_for_lock_wait
    mutation << true
    release << true

    result = Timeout.timeout(10) { thread.value }

    assert result.blocked?
    assert_equal :expired, result.blocked_reason
    assert_not @group.project_group_members.exists?(user_id: @redeemer_user.id)
  ensure
    release << true if release
    thread&.join(1)
    thread&.kill
    holder&.join(1)
    holder&.kill
  end

  test 'a link replaced while the redeemer waits is refused' do
    release = Queue.new
    mutation = Queue.new
    holder = hold_group_lock(release) do
      mutation.pop
      ProjectGroupInviteLink.where(id: @link.id).delete_all
      create(:project_group_invite_link, project_group: @group, sender: @leader,
                                         token: 'replacement-token', expires_at: 1.hour.from_now)
    end
    thread = redeemer_thread(@redeemer_user)

    wait_for_lock_wait
    mutation << true
    release << true

    result = Timeout.timeout(10) { thread.value }

    assert result.blocked?
    assert_equal :expired, result.blocked_reason
    assert_not @group.project_group_members.exists?(user_id: @redeemer_user.id)
  ensure
    release << true if release
    thread&.join(1)
    thread&.kill
    holder&.join(1)
    holder&.kill
  end

  test 'two redeemers racing for the last slot join only once' do
    release = Queue.new
    held = Queue.new
    holder = Thread.new do
      with_connection do
        ProjectGroup.transaction do
          ProjectGroup.lock.find(@group.id)
          held << true
          release.pop
        end
      end
    end

    held.pop
    start = Queue.new
    threads = @contenders.map do |user|
      Thread.new do
        with_connection do
          start.pop
          GroupInviteLinkRedeemer.new(ProjectGroupInviteLink.find(@link.id), current_user: user).redeem!
        end
      end
    end

    2.times { start << true }
    wait_for_lock_waits(2)
    release << true

    results = Timeout.timeout(10) { threads.map(&:value) }
    redeemed = results.select(&:redeemed?)
    blocked = results.select(&:blocked?)

    assert_equal 1, redeemed.length
    assert_equal 1, blocked.length
    assert_equal :group_full, blocked.first.blocked_reason
    assert_equal 3, @group.project_group_members.count
  ensure
    release << true if release
    (threads || []).each { |thread| thread.join(1) || thread.kill }
    holder&.join(1)
    holder&.kill
  end

  private

  def redeemer_thread(user)
    Thread.new do
      with_connection do
        GroupInviteLinkRedeemer.new(ProjectGroupInviteLink.find(@link.id), current_user: user).redeem!
      end
    end
  end

  def hold_group_lock(release)
    held = Queue.new

    thread = Thread.new do
      with_connection do
        ProjectGroup.transaction do
          ProjectGroup.lock.find(@group.id)
          held << true
          yield if block_given?
          release.pop
        end
      end
    end

    held.pop
    thread
  end
end
