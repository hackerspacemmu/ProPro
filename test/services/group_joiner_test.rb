# test/services/group_joiner_test.rb
require 'test_helper'

class GroupJoinerTest < ActiveSupport::TestCase
  setup do
    @course = FactoryBot.create(:course,
                                grouped: true, grouping_enabled: true, grouping_open: true,
                                group_min: 2, group_max: 3, student_list_finalised: false)
    @leader  = FactoryBot.create(:user)
    @student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: @leader,  role: :student)
    FactoryBot.create(:enrolment, course: @course, user: @student, role: :student)

    @group = FactoryBot.create(:project_group, course: @course, leader_id: @leader.id)
    FactoryBot.create(:project_group_member, project_group: @group, user: @leader)
  end

  test 'join succeeds, adds member' do
    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.joined?
    assert @group.project_group_members.exists?(user_id: @student.id)
  end

  test 'blocked when window closed' do
    @course.update!(grouping_open: false)

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

  test 'blocked when group locked' do
    @group.update!(locked: true)

    result = GroupJoiner.new(@group, current_user: @student).join!

    assert result.blocked?
    assert_equal :group_locked, result.blocked_reason
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

  test "join clears joiner's own pending request invites course-wide" do
    other_group = FactoryBot.create(:project_group, course: @course, leader_id: @leader.id)
    invite = FactoryBot.create(:project_group_invite,
                               project_group: other_group, sender: @student, kind: :request, status: :pending)

    GroupJoiner.new(@group, current_user: @student).join!

    assert_raises(ActiveRecord::RecordNotFound) { invite.reload }
  end

  test "join does not touch other users' pending invites" do
    other_student = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: other_student, role: :student)
    unrelated_invite = FactoryBot.create(:project_group_invite,
                                         project_group: @group, sender: other_student, kind: :request, status: :pending)

    GroupJoiner.new(@group, current_user: @student).join!

    assert unrelated_invite.reload.persisted?
  end

  test 'concurrent joins on last slot — only one succeeds' do
    filler = FactoryBot.create(:user)
    FactoryBot.create(:enrolment, course: @course, user: filler, role: :student)
    FactoryBot.create(:project_group_member, project_group: @group, user: filler)
    # group_max: 3, currently 2 (leader+filler) — exactly 1 slot left

    contender_a = FactoryBot.create(:user)
    contender_b = FactoryBot.create(:user)
    [contender_a, contender_b].each { |u| FactoryBot.create(:enrolment, course: @course, user: u, role: :student) }

    results = [contender_a, contender_b].map do |user|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          GroupJoiner.new(ProjectGroup.find(@group.id), current_user: user).join!
        end
      end
    end.map(&:value)

    joined = results.select(&:joined?)
    blocked = results.select(&:blocked?)

    assert_equal 1, joined.length
    assert_equal 1, blocked.length
    assert_equal :group_full, blocked.first.blocked_reason
  end
end
