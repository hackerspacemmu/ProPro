require 'test_helper'

class CourseGroupNamingTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, :grouped)
  end

  test 'starts at the first number when the course has no groups' do
    assert_equal 'Tmp001', @course.lowest_free_tmp_group_name
    assert_equal 'G001', @course.lowest_free_confirmed_group_name
  end

  test 'fills the lowest gap in the confirmed numbers' do
    create_group('G001')
    create_group('G002')
    create_group('G004')

    assert_equal 'G003', @course.lowest_free_confirmed_group_name
  end

  test 'a deleted group frees its number' do
    create_group('G001')
    gap = create_group('G002')
    create_group('G003')
    gap.destroy!

    assert_equal 'G002', @course.lowest_free_confirmed_group_name
  end

  test 'an imported group holds its number' do
    create_group('G001')
    create_group('G002')
    create(:project_group, :imported, course: @course, group_name: 'G003')

    assert_equal 'G004', @course.lowest_free_confirmed_group_name
  end

  test 'only exact candidate names are taken' do
    create_group('G001')
    create_group('G002')
    create_group('G3')
    create_group('g003')
    create_group('Team Alpha')
    create_group('G003 (Team A)')

    assert_equal 'G003', @course.lowest_free_confirmed_group_name
  end

  test 'the temporary and confirmed numbers are independent' do
    create_group('Tmp001')

    assert_equal 'Tmp002', @course.lowest_free_tmp_group_name
    assert_equal 'G001', @course.lowest_free_confirmed_group_name
  end

  test 'excluding a group ignores its own name' do
    group = create_group('G001')
    create_group('G002')

    assert_equal 'G001', @course.lowest_free_confirmed_group_name(excluding: group)
  end

  test 'numbers above 999 keep working' do
    names = (1..999).map { |number| format('G%03d', number) } + ['G1000']
    ProjectGroup.insert_all( # rubocop:disable Rails/SkipsModelValidations -- bulk insert to reach the 1000+ range
      names.map do |name|
        { course_id: @course.id, group_name: name, created_at: Time.current, updated_at: Time.current }
      end
    )

    assert_equal 'G1001', @course.lowest_free_confirmed_group_name
  end

  private

  def create_group(name)
    create(:project_group, course: @course, group_name: name)
  end
end
