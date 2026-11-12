# test/services/group_joiner_test.rb
require 'test_helper'

class GroupJoinerTest < ActiveSupport::TestCase
  setup do
    @course = FactoryBot.create(:course,
                                grouped: true, grouping_enabled: true,
                                group_min: 2, group_max: 3, student_list_finalised: false)
    @leader  = FactoryBot.create(:user)
    @student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: @leader,  role: :student)
    FactoryBot.create(:enrolment, course: @course, user: @student, role: :student)

    @group = FactoryBot.create(:project_group, course: @course, leader_id: @leader.id)
    FactoryBot.create(:project_group_member, project_group: @group, user: @leader)
  end

  test 'blocked for an imported group' do
    @group.update!(confirmed: true, origin: :import)

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :imported_group, result.blocked_reason
  end

  test 'join succeeds when the course has no size limits' do
    @course.update_columns(group_min: nil, group_max: nil)

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.joined?
    assert @group.project_group_members.exists?(user_id: @student.id)
  end

  test 'join succeeds, adds member' do
    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.joined?
    assert @group.project_group_members.exists?(user_id: @student.id)
  end

  test "join clears joiner's own pending request invites course-wide" do
    other_group = FactoryBot.create(:project_group, course: @course, leader_id: @leader.id)
    invite = FactoryBot.create(:project_group_invite,
                               project_group: other_group, sender: @student, recipient: @leader,
                               kind: :direct_request, status: :pending)

    GroupJoiner.new(@group, current_user: @student).join!

    assert_raises(ActiveRecord::RecordNotFound) { invite.reload }
  end

  test 'join clears pending invites received by the joiner course-wide' do
    other_group = FactoryBot.create(:project_group, course: @course, leader_id: @leader.id)
    invite = FactoryBot.create(:project_group_invite,
                               project_group: other_group, sender: @leader, recipient: @student,
                               kind: :direct_invite, status: :pending)

    GroupJoiner.new(@group, current_user: @student).join!

    assert_not ProjectGroupInvite.exists?(invite.id)
  end

  test "join does not touch other users' pending invites" do
    other_student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: other_student, role: :student)
    unrelated_invite = FactoryBot.create(:project_group_invite,
                                         project_group: @group, sender: other_student, recipient: @leader,
                                         kind: :direct_request, status: :pending)

    GroupJoiner.new(@group, current_user: @student).join!

    assert unrelated_invite.reload.persisted?
  end

  test 'blocked when window closed' do
    @course.update!(grouping_closes_at: 1.hour.ago)

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'blocked when already grouped elsewhere in course' do
    other_group = FactoryBot.create(:project_group, course: @course, leader_id: @student.id)
    FactoryBot.create(:project_group_member, project_group: other_group, user: @student)

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'blocked when group confirmed' do
    @group.update!(confirmed: true)

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :group_confirmed, result.blocked_reason
  end

  test 'blocked when group full' do
    filler = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: filler, role: :student)
    FactoryBot.create(:project_group_member, project_group: @group, user: filler)
    another = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: another, role: :student)
    FactoryBot.create(:project_group_member, project_group: @group, user: another)
    # group_max: 3, now at 3 with leader+filler+another

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :group_full, result.blocked_reason
  end

  test 'blocked when the joiner is no longer enrolled in the course' do
    Enrolment.find_by!(user: @student, course: @course).destroy!

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :not_enrolled, result.blocked_reason
    assert_not @group.project_group_members.exists?(user_id: @student.id)
  end
end

class GroupJoinerRaceTest < NonTransactionalTestCase
  setup do
    @course = create(:course, grouped: true, grouping_enabled: true,
                              group_min: 2, group_max: 3, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)

    filler = create(:user)
    create(:enrolment, course: @course, user: filler, role: :student)
    create(:project_group_member, project_group: @group, user: filler)

    @contenders = [create(:user), create(:user)]
    @contenders.each { |user| create(:enrolment, course: @course, user: user, role: :student) }
  end

  test 'a second concurrent join for the last slot is blocked as full' do
    release = Queue.new
    holder = hold_group_lock(release)
    start = Queue.new

    threads = @contenders.map do |user|
      Thread.new do
        with_connection do
          start.pop
          GroupJoiner.new(ProjectGroup.find(@group.id), current_user: user).join!
        end
      end
    end

    2.times { start << true }
    wait_for_lock_waits(2)
    release << true

    results = Timeout.timeout(10) { threads.map(&:value) }
    joined = results.select(&:joined?)
    blocked = results.select(&:blocked?)

    assert_equal 1, joined.length
    assert_equal 1, blocked.length
    assert_equal :group_full, blocked.first.blocked_reason
  ensure
    release << true if release
    (threads || []).each { |thread| thread.join(1) || thread.kill }
    holder&.join(1)
    holder&.kill
  end

  test 'a join waiting on the group lock does not add a student removed from the course' do
    release = Queue.new
    holder = hold_group_lock(release)
    student = @contenders.first
    thread = nil

    thread = Thread.new do
      with_connection { GroupJoiner.new(ProjectGroup.find(@group.id), current_user: student).join! }
    end

    wait_for_lock_wait
    Enrolment.find_by!(user: student, course: @course).destroy!
    release << true

    result = Timeout.timeout(10) { thread.value }

    assert result.blocked?
    assert_equal :not_enrolled, result.blocked_reason
    assert_not @group.project_group_members.exists?(user_id: student.id)
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
