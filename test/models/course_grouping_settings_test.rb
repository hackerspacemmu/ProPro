# test/models/course_grouping_settings_test.rb

require 'test_helper'

class CourseGroupingSettingsTest < ActiveSupport::TestCase
  # Validations

  test 'grouping is valid with blank size limits' do
    course = build(:course, group_formation_enabled: true, group_min: nil, group_max: nil)
    assert course.valid?
  end

  test 'prevent leftover students requires a group_min' do
    course = build(:course, group_formation_enabled: true, student_list_finalised: true,
                            group_min: nil, group_max: 4)
    assert_not course.valid?
    assert course.errors[:group_min].any?
  end

  test 'prevent leftover students requires a group_max' do
    course = build(:course, group_formation_enabled: true, student_list_finalised: true,
                            group_min: 2, group_max: nil)
    assert_not course.valid?
    assert course.errors[:group_max].any?
  end

  test 'group_min must be greater than zero' do
    course = build(:course, group_formation_enabled: true, group_min: 0, group_max: 4)
    assert_not course.valid?
    assert course.errors[:group_min].any?
  end

  test 'group_max must be greater than or equal to group_min' do
    course = build(:course, group_formation_enabled: true, group_min: 4, group_max: 3)
    assert_not course.valid?
    assert course.errors[:group_max].any?
  end

  test 'group_min and group_max are not required when grouping is disabled' do
    course = build(:course, group_formation_enabled: false, group_min: nil, group_max: nil)
    assert course.valid?
  end

  # group_formation_open?

  test 'group_formation_open? returns false when grouping is disabled' do
    course = create(:course, group_formation_enabled: false)
    assert_not course.group_formation_open?
  end

  test 'group_formation_open? returns true when grouping is enabled and no end date is set' do
    course = create(:course, group_formation_enabled: true, group_min: 2, group_max: 4)
    assert course.group_formation_open?
  end

  test 'group_formation_open? returns true when the end date is in the future' do
    course = create(:course,
                    group_formation_enabled: true,
                    group_min: 2,
                    group_max: 4,
                    group_formation_closes_at: 1.hour.from_now)
    assert course.group_formation_open?
  end

  test 'group_formation_open? returns false when the end date has passed' do
    course = create(:course,
                    group_formation_enabled: true,
                    group_min: 2,
                    group_max: 4,
                    group_formation_closes_at: 1.hour.ago)
    assert_not course.group_formation_open?
  end
end
