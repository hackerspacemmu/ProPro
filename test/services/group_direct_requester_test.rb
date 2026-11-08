require 'test_helper'

class GroupDirectRequesterTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  setup do
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
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

  test 'blocked when the group is not confirmed' do
    @group.update!(confirmed: false)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :group_not_confirmed, result.blocked_reason
  end

  test 'blocked when group has no leader' do
    @group.update!(leader_id: nil)

    result = GroupDirectRequester.new(@group, current_user: @student).request!

    assert result.blocked?
    assert_equal :no_leader_assigned, result.blocked_reason
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
    @course = create(:course, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id, confirmed: true)
    create(:project_group_member, project_group: @group, user: @leader)

    @student = create(:user)
    create(:enrolment, course: @course, user: @student, role: :student)
  end

  test 'concurrent duplicate requests — DB unique index catches the race, not app logic' do
    start = Queue.new
    passed_validation = Queue.new
    resume = Queue.new
    threads = []

    subscriber = lambda do |*args|
      sql = args.last[:sql]
      next unless sql.include?('FROM "project_group_invites"') && sql.include?('LIMIT')

      passed_validation << true
      resume.pop
    end

    ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
      threads = Array.new(2) do
        Thread.new do
          with_connection do
            start.pop
            GroupDirectRequester.new(ProjectGroup.find(@group.id), current_user: @student).request!
          end
        end
      end

      2.times { start << true }
      2.times { passed_validation.pop }
      2.times { resume << true }
      results = Timeout.timeout(10) { threads.map(&:value) }
      run_assertions(results)
    end
  ensure
    (threads || []).each { |thread| thread.join(1) || thread.kill }
  end

  private

  def run_assertions(results)
    requested = results.select(&:requested?)
    blocked   = results.select(&:blocked?)

    assert_equal 1, requested.length
    assert_equal 1, blocked.length
    assert_equal :already_requested, blocked.first.blocked_reason
    assert_equal 1, ProjectGroupInvite.where(project_group: @group, sender: @student).count
  end
end
