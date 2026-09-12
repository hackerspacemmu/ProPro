require 'application_system_test_case'

# Solo instructor mode + topic-system toggleable behaviors on courses/show
# (ADR-0006 consequences: no system coverage existed for these variants).
# All four tabs render in the DOM; rack_test treats the non-active panels as
# present, so tab switching is not required for these assertions.
class SoloTopicsToggleTest < ApplicationSystemTestCase
  setup do
    @course = create(:course, toggle_topics: false)
    @coordinator_user = create(:user)
    @coordinator_enrolment = create(:enrolment, :coordinator, user: @coordinator_user, course: @course)
    @lecturer_user = create(:user, :staff)
    @lecturer_enrolment = create(:enrolment, :lecturer, user: @lecturer_user, course: @course)
  end

  test 'topics-disabled course shows the empty state instead of the directory' do
    login_as @coordinator_user
    visit course_path(@course)

    assert_text 'Topics are disabled for this course'
    assert_no_text 'Create'
    assert_no_text 'No topics are currently available'
  end

  test 'coordinator gets a settings CTA in the topics-disabled empty state' do
    login_as @coordinator_user
    visit course_path(@course)

    assert_link 'Go to settings', href: settings_course_path(@course)
  end

  test 'non-coordinator sees the topics-disabled empty state with no CTA' do
    login_as @lecturer_user
    visit course_path(@course)

    assert_text 'Topics are disabled for this course'
    assert_no_link 'Go to settings'
  end

  test 'topics-disabled overview hides Pending Topics for coordinators' do
    login_as @coordinator_user
    visit course_path(@course)

    assert_no_text 'Pending Topics'
    assert_no_text 'Topics that are pending review from you will appear here'
  end

  test 'solo course People tab header reads Instructor (no capacity)' do
    login_as @coordinator_user
    visit course_path(@course)

    within '#panel-people' do
      assert_text 'Instructor'
      assert_no_text 'pending'
    end
    assert_no_text 'Lecturers'
  end

  test 'Overview has no solo instructor card' do
    login_as @coordinator_user
    visit course_path(@course)

    assert_no_selector '#supervisors-available'
  end

  test 'multi-supervisor course People tab keeps the Lecturers header' do
    second_lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: second_lecturer, course: @course)

    login_as @coordinator_user
    visit course_path(@course)

    within '#panel-people' do
      assert_text 'Lecturers'
      assert_no_text 'Instructor'
    end
  end
end
