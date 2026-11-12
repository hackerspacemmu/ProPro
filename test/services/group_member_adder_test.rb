require 'test_helper'

class GroupMemberAdderTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, group_formation_enabled: true,
                              group_min: 3, group_max: 3, prevent_leftover_students: false)
    @leader = create(:user)
    create(:enrolment, course: @course, user: @leader, role: :student)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)

    @coordinator = create(:user)
    create(:enrolment, course: @course, user: @coordinator, role: :coordinator)

    @student = create(:user)
    create(:enrolment, course: @course, user: @student, role: :student)
  end

  test 'coordinator adds a student directly, bypassing size legality for a not-confirmed group' do
    result = GroupMemberAdder.new(@group, user: @student, current_user: @coordinator).add!

    assert result.added?
    assert @group.project_group_members.exists?(user_id: @student.id)
  end

  test 'blocked when student is already grouped elsewhere in the course' do
    other_group = create(:project_group, course: @course, leader_id: @student.id)
    create(:project_group_member, project_group: other_group, user: @student)

    result = GroupMemberAdder.new(@group, user: @student, current_user: @coordinator).add!

    assert result.blocked?
    assert_equal :already_grouped, result.blocked_reason
  end

  test 'coordinator can add above group_max and the group status does not change' do
    2.times do
      filler = create(:user)
      create(:enrolment, course: @course, user: filler, role: :student)
      create(:project_group_member, project_group: @group, user: filler)
    end
    assert_equal @course.group_max, @group.project_group_members.count

    result = GroupMemberAdder.new(@group, user: @student, current_user: @coordinator).add!

    assert result.added?
    assert_operator @group.project_group_members.reload.count, :>, @course.group_max
    assert_not @group.reload.confirmed?
  end

  test 'blocked when the user has no enrolment in the course' do
    outsider = create(:user)

    result = GroupMemberAdder.new(@group, user: outsider, current_user: @coordinator).add!

    assert result.blocked?
    assert_equal :not_enrolled, result.blocked_reason
    assert_not @group.project_group_members.exists?(user_id: outsider.id)
  end

  test 'blocked when the user is enrolled as a lecturer rather than a student' do
    lecturer = create(:user)
    create(:enrolment, course: @course, user: lecturer, role: :lecturer)

    result = GroupMemberAdder.new(@group, user: lecturer, current_user: @coordinator).add!

    assert result.blocked?
    assert_equal :not_enrolled, result.blocked_reason
  end

  test 'clears the added student\'s pending invites course-wide' do
    other_group = create(:project_group, course: @course, leader_id: @leader.id)
    sent = create(:project_group_invite, project_group: other_group, sender: @student,
                                         recipient: @leader, kind: :direct_request, status: :pending)
    received = create(:project_group_invite, project_group: other_group, sender: @leader,
                                             recipient: @student, kind: :direct_invite, status: :pending)

    GroupMemberAdder.new(@group, user: @student, current_user: @coordinator).add!

    assert_not ProjectGroupInvite.exists?(sent.id)
    assert_not ProjectGroupInvite.exists?(received.id)
  end
end
