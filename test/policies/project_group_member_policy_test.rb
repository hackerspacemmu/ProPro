require 'test_helper'

class ProjectGroupMemberPolicyTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, :grouped)
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

  test 'the member and leader cannot remove members from a confirmed group' do
    @group.update!(confirmed: true)

    assert_not ProjectGroupMemberPolicy.new(@member, @membership).destroy?
    assert_not ProjectGroupMemberPolicy.new(@leader, @membership).destroy?
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
