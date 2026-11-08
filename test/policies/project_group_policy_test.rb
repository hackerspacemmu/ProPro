require 'test_helper'

class ProjectGroupPolicyTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
    @leader = create(:user)
    @coordinator = create(:user, :staff)
    @student = create(:user)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    create(:enrolment, user: @student, course: @course)
    @group = create(:project_group, course: @course, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)
  end

  test 'request_to_join? is false for a student, a leader and a coordinator' do
    assert_not ProjectGroupPolicy.new(@student, @group).request_to_join?
    assert_not ProjectGroupPolicy.new(@leader, @group).request_to_join?
    assert_not ProjectGroupPolicy.new(@coordinator, @group).request_to_join?
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

  test 'a formation group can be reverted' do
    @group.update!(confirmed: true)

    assert ProjectGroupPolicy.new(@leader, @group).revert?
    assert ProjectGroupPolicy.new(@coordinator, @group).revert?
  end

  test 'an imported group cannot be reverted' do
    @group.update!(confirmed: true, origin: :import)

    assert_not ProjectGroupPolicy.new(@leader, @group).revert?
    assert_not ProjectGroupPolicy.new(@coordinator, @group).revert?
  end

  test 'a lecturer cannot create, confirm, revert or edit a group' do
    lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: lecturer, course: @course)

    assert_not ProjectGroupPolicy.new(lecturer, @group).create?
    assert_not ProjectGroupPolicy.new(lecturer, @group).confirm?
    assert_not ProjectGroupPolicy.new(lecturer, @group).revert?
    assert_not ProjectGroupPolicy.new(lecturer, @group).edit?
  end

  test 'a coordinator can create, confirm, revert and edit a group' do
    assert ProjectGroupPolicy.new(@coordinator, @group).create?
    assert ProjectGroupPolicy.new(@coordinator, @group).confirm?
    assert ProjectGroupPolicy.new(@coordinator, @group).revert?
    assert ProjectGroupPolicy.new(@coordinator, @group).edit?
  end

  test 'a student leader can confirm and revert their own group' do
    leader = create(:user)
    create(:enrolment, user: leader, course: @course)
    group = create(:project_group, course: @course, leader_id: leader.id)
    create(:project_group_member, project_group: group, user: leader)

    assert ProjectGroupPolicy.new(leader, group).confirm?
    assert ProjectGroupPolicy.new(leader, group).revert?
  end
end
