require 'test_helper'

class GroupDirectRequesterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @course = create(:course, group_formation_enabled: true,
                              group_min: 2, group_max: 3, prevent_leftover_students: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id, confirmed: true)
    create(:project_group_member, project_group: @group, user: @leader)

    @student = create(:user)
    create(:enrolment, course: @course, user: @student, role: :student)
  end

  test 'student requests a confirmed group with a leader — pending direct_request created, mailer queued' do
    assert_enqueued_jobs 1 do
      result = GroupDirectRequester.new(@group, current_user: @student).request!
      assert result.requested?
    end

    invite = ProjectGroupInvite.find_by(project_group: @group, sender: @student)
    assert invite.present?
    assert invite.direct_request?
    assert_equal @leader.id, invite.recipient_id
  end

  test 'blocked when the requester is no longer enrolled in the course' do
    Enrolment.find_by!(user: @student, course: @course).destroy!

    assert_no_difference('ProjectGroupInvite.count') do
      result = GroupDirectRequester.new(@group, current_user: @student).request!
      assert result.blocked?
      assert_equal :not_enrolled, result.blocked_reason
    end
  end

  test 'blocked when formation closed' do
    @course.update!(group_formation_closes_at: 1.hour.ago)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :formation_closed, result.blocked_reason
  end

  test 'blocked when already grouped' do
    other_group = create(:project_group, course: @course, leader_id: @student.id)
    create(:project_group_member, project_group: other_group, user: @student)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'blocked when the group is not confirmed' do
    @group.update!(confirmed: false)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :group_not_confirmed, result.blocked_reason
  end

  test 'blocked for an imported group' do
    @group.update!(origin: :import)

    assert_no_difference('ProjectGroupInvite.count') do
      result = GroupDirectRequester.new(@group, current_user: @student).request!

      assert result.blocked?
      assert_equal :imported_group, result.blocked_reason
    end
  end

  test 'blocked when the group has a project' do
    @group.update!(confirmed: true)
    supervisor = create(:enrolment, :lecturer, course: @course)
    Project.create!(course: @course, owner: @group, supervisor_enrolment: supervisor)

    assert_no_difference('ProjectGroupInvite.count') do
      result = GroupDirectRequester.new(@group, current_user: @student).request!

      assert result.blocked?
      assert_equal :has_project, result.blocked_reason
    end
  end

  test 'blocked when group has no leader' do
    @group.update!(leader_id: nil)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :no_leader_assigned, result.blocked_reason
  end

  test 'blocked when the group is full' do
    @course.update!(group_min: 1, group_max: 1)

    assert_no_difference('ProjectGroupInvite.count') do
      result = GroupDirectRequester.new(@group, current_user: @student).request!

      assert result.blocked?
      assert_equal :group_full, result.blocked_reason
    end
  end

  test 'an expired pending request is replaced by a new one' do
    GroupDirectRequester.new(@group, current_user: @student).request!
    old = ProjectGroupInvite.find_by!(project_group: @group, sender: @student)

    result = travel_to(25.hours.from_now) do
      GroupDirectRequester.new(@group, current_user: @student).request!
    end

    assert result.requested?
    assert_not ProjectGroupInvite.exists?(old.id)
    assert_equal 1, ProjectGroupInvite.where(project_group: @group, sender: @student,
                                             kind: :direct_request, status: :pending).count
  end

  test 'duplicate pending request is rescued into already_requested' do
    GroupDirectRequester.new(@group, current_user: @student).request!

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :already_requested, result.blocked_reason
    assert_equal 1, ProjectGroupInvite.where(project_group: @group, sender: @student).count
  end

  test 'an unrelated RecordInvalid propagates instead of becoming already_requested' do
    invalid = ProjectGroupInvite.new
    invalid.errors.add(:project_group, :blank)
    error = ActiveRecord::RecordInvalid.new(invalid)

    ProjectGroupInvite.stub(:create!, ->(*, **) { raise error }) do
      assert_raises(ActiveRecord::RecordInvalid) do
        GroupDirectRequester.new(@group, current_user: @student).request!
      end
    end
  end
end

class GroupDirectRequesterRaceTest < NonTransactionalTestCase
  setup do
    @course = create(:course, group_formation_enabled: true,
                              group_min: 2, group_max: 3, prevent_leftover_students: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id, confirmed: true)
    create(:project_group_member, project_group: @group, user: @leader)

    @student = create(:user)
    create(:enrolment, course: @course, user: @student, role: :student)
  end

  test 'concurrent duplicate requests are serialised by the group lock' do
    start = Queue.new
    threads = Array.new(2) do
      Thread.new do
        with_connection do
          start.pop
          GroupDirectRequester.new(ProjectGroup.find(@group.id), current_user: @student).request!
        end
      end
    end

    2.times { start << true }
    results = Timeout.timeout(10) { threads.map(&:value) }

    requested = results.select(&:requested?)
    blocked   = results.select(&:blocked?)

    assert_equal 1, requested.length
    assert_equal 1, blocked.length
    assert_equal :already_requested, blocked.first.blocked_reason
    assert_equal 1, ProjectGroupInvite.where(project_group: @group, sender: @student).count
  ensure
    (threads || []).each { |thread| thread.join(1) || thread.kill }
  end
end
