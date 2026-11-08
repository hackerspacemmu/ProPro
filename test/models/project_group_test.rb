require 'test_helper'

class ProjectGroupTest < ActiveSupport::TestCase
  test 'defaults to formation origin' do
    group = create(:project_group)

    assert group.origin_formation?
  end

  test 'accepts imported origin' do
    group = create(:project_group, :imported)

    assert group.origin_import?
    assert group.confirmed?
  end

  test 'is confirmable at any non-zero size when the course has no limits' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: nil, group_max: nil)
    group = create(:project_group, course: course)
    create(:project_group_member, project_group: group)
    assert group.confirmable?

    create(:project_group_member, project_group: group)
    assert group.confirmable?
  end

  test 'is not confirmable when the group is empty' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: nil, group_max: nil)
    group = create(:project_group, course: course)

    assert_not group.confirmable?
  end

  test 'is confirmable within set limits' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    group = create(:project_group, course: course)
    create_list(:project_group_member, 1, project_group: group)
    assert_not group.confirmable?

    create(:project_group_member, project_group: group)
    assert group.confirmable?

    create_list(:project_group_member, 2, project_group: group)
    assert group.confirmable?

    create(:project_group_member, project_group: group)
    assert_not group.confirmable?
  end

  test 'uses the calculator in prevent-leftover mode' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    group = create(:project_group, course: course)
    create_list(:project_group_member, 2, project_group: group)

    Queries::GroupSizeConfirmabilityCalculator.stub(:new, ->(*) { raise 'calculator used' }) do
      assert_raises(RuntimeError) { group.confirmable? }
    end
  end

  test 'rejects an unknown origin' do
    group = build(:project_group, origin: 'unknown')

    assert_not group.valid?
    assert group.errors.added?(:origin, :inclusion, value: 'unknown')
  end
end
