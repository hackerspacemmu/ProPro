require 'application_system_test_case'

class SettingsSaveTest < ApplicationSystemTestCase
  setup do
    @course = create(:course,
                     course_name: 'Original Course Name',
                     starting_week: 1,
                     course_description: 'Old description')
    coordinator = create(:user)
    create(:enrolment, :coordinator, user: coordinator, course: @course)
    @coordinator = coordinator
  end

  test 'settings page renders the four section cards with the coursecode widget in General' do
    login_as @coordinator
    visit settings_course_path(@course)

    assert_current_path settings_course_path(@course)

    within 'main' do
      assert_text 'Class Details'
      assert_text 'General'
      assert_text 'Permissions and Rules'
      assert_text 'Student Self-Grouping'
    end

    # The coursecode widget lives inside the General section of the settings
    # form, but it is formless (ADR-0010): no <form> of its own, so it cannot
    # nest a form or roll a settings save back on generate. (Page-wide there is
    # also the chrome header's log-out button_to form.)
    assert_selector '#course-settings-form'
    assert_selector '#course_code_form'
    assert_selector "#course_code_form a[href*='update_coursecode']"
    assert_equal 0, page.all('#course_code_form form').count,
                 'the coursecode widget must never render a <form>'
    assert_equal 0, page.all('#course-settings-form form').count,
                 'nothing may nest inside the settings form'
  end

  test 'coordinator can save class details from the settings form' do
    login_as @coordinator
    visit settings_course_path(@course)

    within '#course-settings-form' do
      fill_in 'Course Name', with: 'Updated Course Name'
      fill_in 'Project Details', with: 'New project details'
      click_button 'Save'
    end

    assert_current_path settings_course_path(@course)
    assert_text 'Course successfully updated'

    @course.reload
    assert_equal 'Updated Course Name', @course.course_name
    assert_equal 'New project details', @course.course_description
  end
end