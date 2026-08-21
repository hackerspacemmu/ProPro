require 'test_helper'

class GroupDirectRequesterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
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

  test 'student requests a locked, unconfirmed group with a leader — pending direct_request created, mailer queued' do
    assert_enqueued_jobs 1 do
      result = GroupDirectRequester.new(@group, current_user: @student).request!
      assert result.requested?
    end

    invite = ProjectGroupInvite.find_by(project_group: @group, sender: @student)
    assert invite.present?
    assert invite.direct_request?
    assert_equal @leader.id, invite.recipient_id
  end

  test 'blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocked when already grouped' do
    other_group = create(:project_group, course: @course, leader_id: @student.id)
    create(:project_group_member, project_group: other_group, user: @student)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'blocked when group already confirmed' do
    create(:project_group_member, project_group: @group)
    @group.update!(confirmed: true)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  test 'blocked when locked group has no leader' do
    @group.update!(leader_id: nil)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :no_leader_assigned, result.blocked_reason
  end

  test 'blocked when group is unlocked — should join directly instead' do
    @group.update!(locked: false)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :group_unlocked, result.blocked_reason
  end

  test 'duplicate pending request is rescued into already_requested' do
    GroupDirectRequester.new(@group, current_user: @student).request!

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :already_requested, result.blocked_reason
    assert_equal 1, ProjectGroupInvite.where(project_group: @group, sender: @student).count
  end

  # ── Edge: no with_lock — relies entirely on the DB unique partial index ───────

  test 'concurrent duplicate requests — DB unique index catches the race, not app logic' do
    results = Array.new(2) do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          GroupDirectRequester.new(ProjectGroup.find(@group.id), current_user: @student).request!
        end
      end
    end.map(&:value)

    requested = results.select(&:requested?)
    blocked   = results.select(&:blocked?)

    assert_equal 1, requested.length
    assert_equal 1, blocked.length
    assert_equal :already_requested, blocked.first.blocked_reason
    assert_equal 1, ProjectGroupInvite.where(project_group: @group, sender: @student).count
  end
end