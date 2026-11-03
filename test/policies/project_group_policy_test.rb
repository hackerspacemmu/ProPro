require 'test_helper'

class ProjectGroupPolicyTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
    @leader = create(:user)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)
  end

  test 'the leader can delete a not-confirmed group while formation is open' do
    assert ProjectGroupPolicy.new(@leader, @group).destroy?
  end

  test 'the leader cannot delete a confirmed group' do
    @group.update!(confirmed: true)

    assert_not ProjectGroupPolicy.new(@leader, @group).destroy?
  end

  test 'a coordinator can delete a group in any state' do
    assert ProjectGroupPolicy.new(@coordinator, @group).destroy?

    @group.update!(confirmed: true)
    assert ProjectGroupPolicy.new(@coordinator, @group).destroy?
  end

  test 'a coordinator with an earlier lecturer enrolment can delete a confirmed group' do
    dual_role = create(:user)
    create(:enrolment, :lecturer, user: dual_role, course: @course)
    create(:enrolment, :coordinator, user: dual_role, course: @course)
    @group.update!(confirmed: true)

    assert ProjectGroupPolicy.new(dual_role, @group).destroy?
  end
end
