# test/models/course_grouping_test.rb

require 'test_helper'

class CourseGroupingTest < ActiveSupport::TestCase
  # Validations

  test 'group_min and group_max are required when grouping is enabled' do
    course = build(:course, grouping_enabled: true, group_min: nil, group_max: nil)
    assert_not course.valid?
    assert course.errors[:group_min].any?
    assert course.errors[:group_max].any?
  end

  test 'group_min must be greater than zero' do
    course = build(:course, grouping_enabled: true, group_min: 0, group_max: 4)
    assert_not course.valid?
    assert course.errors[:group_min].any?
  end

  test 'group_max must be greater than or equal to group_min' do
    course = build(:course, grouping_enabled: true, group_min: 4, group_max: 3)
    assert_not course.valid?
    assert course.errors[:group_max].any?
  end

  test 'group_min and group_max are not required when grouping is disabled' do
    course = build(:course, grouping_enabled: false, group_min: nil, group_max: nil)
    assert course.valid?
  end

  test 'grouping_closes_at must be after grouping_opens_at' do
    course = build(:course,
                   grouping_enabled: true,
                   group_min: 2,
                   group_max: 4,
                   grouping_opens_at: 1.day.from_now,
                   grouping_closes_at: 1.hour.from_now)
    assert_not course.valid?
    assert course.errors[:grouping_closes_at].any?
  end

  test 'grouping window dates are valid when closes_at is after opens_at' do
    course = build(:course,
                   grouping_enabled: true,
                   group_min: 2,
                   group_max: 4,
                   grouping_opens_at: 1.hour.from_now,
                   grouping_closes_at: 1.day.from_now)
    assert course.valid?
  end

  # group_size_distribution

  test 'group_size_distribution returns a valid distribution for exact multiples' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 3)
    result = course.group_size_distribution(9)
    assert_nil result[:error]
    assert_equal 3, result[:total_groups]
    assert_equal [{ size: 3, count: 3 }], result[:groups]
  end

  test 'group_size_distribution returns mixed sizes when remainder exists' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    result = course.group_size_distribution(11)
    assert_nil result[:error]
    sizes = result[:groups].flat_map { |e| Array.new(e[:count], e[:size]) }.sum
    assert_equal 11, sizes
  end

  test 'group_size_distribution returns error when no legal combination exists' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 4, group_max: 4)
    result = course.group_size_distribution(7)
    assert result[:error].present?
  end

  test 'group_size_distribution returns error for zero students' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    result = course.group_size_distribution(0)
    assert result[:error].present?
  end

  test 'group_size_distribution is deterministic, returns the same output' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 3, group_max: 4)
    first  = course.group_size_distribution(11)
    second = course.group_size_distribution(11)
    assert_equal first, second
  end

  # grouping_window_open?

  test 'grouping_window_open? returns false when grouping is disabled' do
    course = create(:course, grouping_enabled: false)
    assert_not course.grouping_window_open?
  end

  test 'grouping_window_open? returns true when grouping is enabled and no window is set' do
    course = create(:course, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
    assert course.grouping_window_open?
  end

  test 'grouping_window_open? returns true when current time is within the window' do
    course = create(:course,
                    grouping_enabled: true,
                    grouping_open: true,
                    group_min: 2,
                    group_max: 4,
                    grouping_opens_at: 1.hour.ago,
                    grouping_closes_at: 1.hour.from_now)
    assert course.grouping_window_open?
  end

  test 'grouping_window_open? returns false when window has closed' do
    course = create(:course,
                    grouping_enabled: true,
                    grouping_open: true,
                    group_min: 2,
                    group_max: 4,
                    grouping_opens_at: 2.hours.ago,
                    grouping_closes_at: 1.hour.ago)
    assert_not course.grouping_window_open?
  end

  test 'grouping_window_open? returns false when window has not opened yet' do
    course = create(:course,
                    grouping_enabled: true,
                    grouping_open: true,
                    group_min: 2,
                    group_max: 4,
                    grouping_opens_at: 1.hour.from_now,
                    grouping_closes_at: 2.hours.from_now)
    assert_not course.grouping_window_open?
  end

  # disable_grouping!

  test 'disable_grouping! sets grouping_enabled to false' do
    course = create(:course, grouping_enabled: true, student_list_finalised: false, group_min: 2, group_max: 4)
    course.disable_grouping!
    assert_not course.reload.grouping_enabled?
  end

  test 'disable_grouping! resets student_list_finalised to false' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    course.disable_grouping!
    assert_not course.reload.student_list_finalised?
  end

  test 'disable_grouping! destroys draft project_groups' do
    course = create(:course, grouping_enabled: true, group_min: 2, group_max: 4)
    draft = create(:project_group, course: course, confirmed: false)
    course.disable_grouping!
    assert_not ProjectGroup.exists?(draft.id)
  end

  test 'disable_grouping! preserves confirmed project_groups' do
    course = create(:course, grouping_enabled: true, group_min: 2, group_max: 4)
    confirmed = create(:project_group, course: course, confirmed: true)
    course.disable_grouping!
    assert ProjectGroup.exists?(confirmed.id)
  end

  # revert_to_default_mode!

  test 'revert_to_default_mode! sets student_list_finalised to false' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    course.revert_to_default_mode!
    assert_not course.reload.student_list_finalised?
  end

  test 'revert_to_default_mode! leaves grouping_enabled true' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    course.revert_to_default_mode!
    assert course.reload.grouping_enabled?
  end

  test 'revert_to_default_mode! destroys draft project_groups' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    draft = create(:project_group, course: course, confirmed: false)
    course.revert_to_default_mode!
    assert_not ProjectGroup.exists?(draft.id)
  end

  test 'revert_to_default_mode! does not destroy confirmed project_groups' do
    course = create(:course, grouping_enabled: true, student_list_finalised: true, group_min: 2, group_max: 4)
    confirmed = create(:project_group, course: course, confirmed: true)
    course.revert_to_default_mode!
    assert ProjectGroup.exists?(confirmed.id)
  end

  test 'grouping_window_open? returns false when grouping_open is false' do
    course = build(:course, grouping_enabled: true, grouping_open: false, group_min: 2, group_max: 4)
    assert_not course.grouping_window_open?
  end

  test 'grouping_window_open? returns true when grouping_enabled and grouping_open with no dates' do
    course = build(:course, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4,
                            grouping_opens_at: nil, grouping_closes_at: nil)
    assert course.grouping_window_open?
  end

  test 'disable_grouping! sets grouping_open to false' do
    course = create(:course, grouping_enabled: true, grouping_open: true, group_min: 2, group_max: 4)
    course.disable_grouping!
    assert_not course.reload.grouping_open?
  end
end
