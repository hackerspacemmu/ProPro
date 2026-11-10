require 'test_helper'

class GroupsCoordinatorConfirmerTest < ActiveSupport::TestCase
  test 'confirms unconfirmed group and renames to lowest free G number' do
    course = create(:course, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
    group = create(:project_group, course: course, confirmed: false, group_name: 'Tmp001')
    create_list(:project_group_member, 3, project_group: group)

    result = Groups::Coordinator::Confirmer.new(group).confirm!

    assert result.confirmed?
    assert group.reload.confirmed?
    assert_equal 'G001', group.group_name
    assert_equal 'Tmp001 is now confirmed as G001.', result.message
  end

  test 'confirms an undersized group bypassing size limits' do
    course = create(:course, grouping_enabled: true, grouping_open: true, group_min: 3, group_max: 5)
    group = create(:project_group, course: course, confirmed: false, group_name: 'Tmp001')
    create_list(:project_group_member, 1, project_group: group)

    result = Groups::Coordinator::Confirmer.new(group).confirm!

    assert result.confirmed?
    assert group.reload.confirmed?
    assert_equal 'G001', group.group_name
  end

  test 'confirms an oversized group bypassing size limits' do
    course = create(:course, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 3)
    group = create(:project_group, course: course, confirmed: false, group_name: 'Tmp001')
    create_list(:project_group_member, 4, project_group: group)

    result = Groups::Coordinator::Confirmer.new(group).confirm!

    assert result.confirmed?
    assert group.reload.confirmed?
    assert_equal 'G001', group.group_name
  end

  test 'confirms a group when the grouping window is closed' do
    course = create(:course, grouping_enabled: true, grouping_open: false, group_min: 2, group_max: 4)
    group = create(:project_group, course: course, confirmed: false, group_name: 'Tmp001')
    create_list(:project_group_member, 2, project_group: group)

    result = Groups::Coordinator::Confirmer.new(group).confirm!

    assert result.confirmed?
    assert group.reload.confirmed?
  end

  test 'blocks when already confirmed' do
    course = create(:course, grouping_enabled: true, grouping_open: true)
    group = create(:project_group, course: course, confirmed: true, group_name: 'G001')

    result = Groups::Coordinator::Confirmer.new(group).confirm!

    assert_not result.confirmed?
    assert_equal :already_confirmed, result.blocked_reason
    assert_equal 'This group has already been confirmed.', result.message
  end
end
