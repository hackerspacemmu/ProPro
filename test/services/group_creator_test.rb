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

  test 'self-create succeeds, becomes sole leader+member' do
    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert result.created?
    assert_nil result.blocked_reason
    group = result.group
    assert_equal @student.id, group.leader_id
    assert_equal 1, group.project_group_members.count
    assert_equal @student.id, group.project_group_members.first.user_id
    assert_match(/^G\d{3}$/, group.group_name)
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

  test 'sequential creates get unique, incrementing sequence numbers' do
    other_student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: other_student, role: :student)

    result_a = GroupCreator.new(@course, leader: @student, current_user: @student).create!
    result_b = GroupCreator.new(@course, leader: other_student, current_user: other_student).create!

    assert_not_equal result_a.group.course_group_sequence, result_b.group.course_group_sequence
    assert_equal result_a.group.course_group_sequence + 1, result_b.group.course_group_sequence
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

  test 'auto-generated group_name silently duplicates an existing CSV-imported group_name' do
    csv_group = FactoryBot.create(:project_group, course: @course, group_name: 'G001', course_group_sequence: nil)

    result = GroupCreator.new(@course, leader: @student, current_user: @student).create!

    assert result.created?
    assert_equal 'G001', result.group.group_name
    assert_not_equal csv_group.id, result.group.id
    assert_equal 2, @course.project_groups.where(group_name: 'G001').count
  end

  test 'concurrent self-creates never collide on course_group_sequence' do
    other_student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: other_student, role: :student)

    results = [@student, other_student].map do |user|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          GroupCreator.new(Course.find(@course.id), leader: user, current_user: user).create!
        end
      end
    end.map(&:value)

    assert results.all?(&:created?)
    sequences = results.map { |r| r.group.course_group_sequence }
    assert_equal sequences.uniq.length, sequences.length, 'expected unique sequence numbers, got a collision'
  end
end
