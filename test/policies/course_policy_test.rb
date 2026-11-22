require 'test_helper'

class CoursePolicyTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, :grouped)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: @lecturer, course: @course)
    @student = create(:user)
    create(:enrolment, user: @student, course: @course)
  end

  test 'a coordinator can manage groups' do
    assert CoursePolicy.new(@coordinator, @course).manage_groups?
  end

  test 'a lecturer cannot manage groups' do
    assert_not CoursePolicy.new(@lecturer, @course).manage_groups?
  end

  test 'a student cannot manage groups' do
    assert_not CoursePolicy.new(@student, @course).manage_groups?
  end

  test 'a user not enrolled cannot manage groups' do
    assert_not CoursePolicy.new(create(:user), @course).manage_groups?
  end

  test 'a coordinator with an earlier lecturer enrolment can manage groups' do
    dual_role = create(:user)
    create(:enrolment, :lecturer, user: dual_role, course: @course)
    create(:enrolment, :coordinator, user: dual_role, course: @course)

    assert CoursePolicy.new(dual_role, @course).manage_groups?
  end
end
