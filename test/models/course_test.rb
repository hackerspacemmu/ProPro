require 'test_helper'

class CourseTest < ActiveSupport::TestCase
  def setup
    @course = Course.create!(
      course_name: 'Test Course',
      grouped: false
    )
  end

  test 'generate_coursecode! generates a code and saves it' do
    assert_nil @course.coursecode

    @course.generate_coursecode!

    assert_not_nil @course.coursecode
    assert_operator @course.coursecode.length, :>=, 6

    # Reload from DB to ensure it was saved
    @course.reload
    assert_not_nil @course.coursecode
  end

  test 'generate_coursecode! raises error if course is grouped' do
    @course.update!(grouped: true)

    error = assert_raises(StandardError) do
      @course.generate_coursecode!
    end

    assert_equal "Course join code can't be used for grouped course", error.message
  end

  test 'generate_coursecode! generates unique codes (randomness)' do
    @course.generate_coursecode!
    code1 = @course.coursecode

    @course.generate_coursecode!
    code2 = @course.coursecode

    assert_not_equal code1, code2
  end

  test 'different courses get different codes' do
    course2 = Course.create!(course_name: 'Course 2', grouped: false)

    @course.generate_coursecode!
    course2.generate_coursecode!

    assert_not_equal @course.coursecode, course2.coursecode
  end
end
