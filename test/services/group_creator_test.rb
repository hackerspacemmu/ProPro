# test/services/group_creator_test.rb
require 'test_helper'

class GroupCreatorTest < ActiveSupport::TestCase
  setup do
    @course = FactoryBot.create(:course,
                                grouped: true, grouping_enabled: true, grouping_open: true,
                                group_min: 2, group_max: 4, student_list_finalised: false)
    @student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: @student, role: :student)
    @coordinator = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: @coordinator, role: :coordinator)
  end

  test 'blocked when the course does not use groups' do
    course = FactoryBot.create(:course, grouped: false)
    student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: course, user: student, role: :student)

    result = GroupCreator.new(course, leader: student, current_user: student).create!

    assert result.blocked?
    assert_equal :not_grouped, result.blocked_reason
    assert_equal 0, course.project_groups.count
  end

  test 'self-create succeeds, becomes sole leader+member' do
    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert result.created?
    assert_nil result.blocked_reason
    group = result.group
    assert_equal @student.id, group.leader_id
    assert_equal 1, group.project_group_members.count
    assert_equal @student.id, group.project_group_members.first.user_id
    assert_equal 'Tmp001', group.group_name
  end

  test 'the success message names the group' do
    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert_equal 'Group Tmp001 created.', result.message
  end

  test 'self-create clears the leader\'s pending invites course-wide' do
    other_group = FactoryBot.create(:project_group, course: @course, leader_id: @coordinator.id)
    invite = FactoryBot.create(:project_group_invite, project_group: other_group, sender: @student,
                                                      recipient: @coordinator, kind: :direct_request, status: :pending)

    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert result.created?
    assert_not ProjectGroupInvite.exists?(invite.id)
  end

  test 'self-create blocked when already grouped' do
    existing = FactoryBot.create(:project_group, course: @course, leader_id: @student.id)
    FactoryBot.create(:project_group_member, project_group: existing, user: @student)

    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'self-create blocked when window closed' do
    @course.update!(grouping_open: false)

    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert result.blocked?
    assert_equal :window_closed, result.blocked_reason
  end

  test 'coordinator-create bypasses window_closed' do
    @course.update!(grouping_open: false)

    result = GroupCreator.new(@course, leader: @student, current_user: @coordinator).create!

    assert result.created?
    assert_equal @student.id, result.group.leader_id
  end

  test 'coordinator-create still blocked if target already grouped' do
    existing = FactoryBot.create(:project_group, course: @course, leader_id: @student.id)
    FactoryBot.create(:project_group_member, project_group: existing, user: @student)

    result = GroupCreator.new(@course, leader: @student, current_user: @coordinator).create!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'sequential creates get incrementing temporary names' do
    other_student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: other_student, role: :student)

    result_a = GroupCreator.new(@course, leader: @student, current_user: @student).create!
    result_b = GroupCreator.new(@course, leader: other_student, current_user: other_student).create!

    assert_equal 'Tmp001', result_a.group.group_name
    assert_equal 'Tmp002', result_b.group.group_name
  end

  test 'deleting the first group frees its temporary number' do
    result_a = GroupCreator.new(@course, leader: @student, current_user: @student).create!
    assert_equal 'Tmp001', result_a.group.group_name
    result_a.group.destroy!

    result_b = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert_equal 'Tmp001', result_b.group.group_name
  end

  test 'failure creating membership rolls back the group, no orphan row' do
    assert_no_difference 'ProjectGroup.count' do
      ProjectGroupMember.stub :create!, ->(*) { raise ActiveRecord::RecordInvalid, ProjectGroupMember.new } do
        assert_raises(ActiveRecord::RecordInvalid) do
          GroupCreator.new(@course, leader: @student, current_user: @student).create!
        end
      end
    end
  end

  test 'coordinator-create currently succeeds even when the leader has no enrolment in the course' do
    outsider = FactoryBot.create(:user) # deliberately NOT enrolled in @course

    result = GroupCreator.new(@course, leader: outsider, current_user: @coordinator).create!

    assert result.created?
    assert_equal outsider.id, result.group.leader_id
  end

  test 'a temporary name is independent of an imported G number' do
    create(:project_group, :imported, course: @course, group_name: 'G001')

    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert result.created?
    assert_equal 'Tmp001', result.group.group_name
    assert_equal 1, @course.project_groups.where(group_name: 'G001').count
  end
end

class GroupCreatorRaceTest < NonTransactionalTestCase
  setup do
    @course = create(:course, grouped: true, grouping_enabled: true, grouping_open: true,
                              group_min: 2, group_max: 4, student_list_finalised: false)
    @students = [create(:user), create(:user)]
    @students.each { |user| create(:enrolment, course: @course, user: user, role: :student) }
  end

  test 'concurrent self-creates never collide on group name' do
    release = Queue.new
    holder = hold_course_lock(release)
    start = Queue.new

    threads = @students.map do |user|
      Thread.new do
        with_connection do
          start.pop
          GroupCreator.new(Course.find(@course.id), leader: user, current_user: user).create!
        end
      end
    end

    2.times { start << true }
    wait_for_lock_waits(2)
    release << true

    results = Timeout.timeout(10) { threads.map(&:value) }

    assert results.all?(&:created?)
    names = results.map { |result| result.group.group_name }
    assert_equal names.uniq.length, names.length, 'expected unique group names, got a collision'
  ensure
    release << true if release
    (threads || []).each { |thread| thread.join(1) || thread.kill }
    holder&.join(1)
    holder&.kill
  end

  private

  def hold_course_lock(release)
    held = Queue.new

    thread = Thread.new do
      with_connection do
        @course.with_no_key_update_lock do
          held << true
          release.pop
        end
      end
    end

    held.pop
    thread
  end
end
