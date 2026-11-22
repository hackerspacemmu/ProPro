require 'test_helper'

class ProjectGroupMemberPolicyTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, :grouped, group_formation_enabled: true)
    @leader = create(:user)
    @member = create(:user)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)
    @membership = create(:project_group_member, project_group: @group, user: @member)
  end

  test 'the member and leader can remove members from a not-confirmed group' do
    assert ProjectGroupMemberPolicy.new(@member, @membership).destroy?
    assert ProjectGroupMemberPolicy.new(@leader, @membership).destroy?
  end

  test 'a member cannot leave a confirmed group' do
    @group.update!(confirmed: true)

    assert_not ProjectGroupMemberPolicy.new(@member, @membership).destroy?
  end

  test 'the leader can remove another member from a confirmed group while formation is open' do
    @group.update!(confirmed: true)

    assert ProjectGroupMemberPolicy.new(@leader, @membership).destroy?
  end

  test 'the leader cannot remove a member from a confirmed group when formation is closed' do
    @group.update!(confirmed: true)
    @course.update!(group_formation_closes_at: 1.hour.ago)

    assert_not ProjectGroupMemberPolicy.new(@leader, @membership).destroy?
  end

  test 'the leader cannot remove a member from a confirmed imported group' do
    @group.update!(confirmed: true, origin: :import)

    assert_not ProjectGroupMemberPolicy.new(@leader, @membership).destroy?
  end

  test 'the leader cannot remove a member from a confirmed group with a project' do
    @group.update!(confirmed: true)
    supervisor = create(:enrolment, :lecturer, course: @course)
    Project.create!(course: @course, owner: @group, supervisor_enrolment: supervisor)

    assert_not ProjectGroupMemberPolicy.new(@leader, @membership).destroy?
  end

  test 'the leader cannot remove their own membership from a confirmed group' do
    @group.update!(confirmed: true)
    leader_membership = @group.project_group_members.find_by!(user: @leader)

    assert_not ProjectGroupMemberPolicy.new(@leader, leader_membership).destroy?
  end

  test 'a coordinator can remove members in any state' do
    assert ProjectGroupMemberPolicy.new(@coordinator, @membership).destroy?

    @group.update!(confirmed: true)
    assert ProjectGroupMemberPolicy.new(@coordinator, @membership).destroy?
  end

  test 'an outsider cannot remove members' do
    assert_not ProjectGroupMemberPolicy.new(create(:user), @membership).destroy?
  end

  test 'a lecturer cannot remove members' do
    lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: lecturer, course: @course)

    assert_not CoursePolicy.new(lecturer, @course).manage_groups?
    assert_not ProjectGroupMemberPolicy.new(lecturer, @membership).destroy?
  end
end
