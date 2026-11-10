require 'application_system_test_case'

class GroupingSettingsTogglesTest < BrowserSystemTestCase
  setup do
    @course = create(:course, grouping_enabled: true)
    @coordinator = create(:user)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
  end

  test 'the prevent-leftover switch shows and hides the distribution preview' do
    @course.update!(student_list_finalised: false)
    login_as @coordinator
    visit settings_course_path(@course)
    wait_for_turbo

    assert_no_selector '[data-grouping-settings-target="previewSection"]'

    click_switch 'Prevent leftover students'
    assert_selector '[data-grouping-settings-target="previewSection"]'

    click_switch 'Prevent leftover students'
    assert_no_selector '[data-grouping-settings-target="previewSection"]'
  end

  test 'the master switch shows and hides the grouping options' do
    login_as @coordinator
    visit settings_course_path(@course)
    wait_for_turbo

    assert_selector '[data-grouping-settings-target="groupingOptions"]'

    click_switch 'Student self-grouping'
    assert_no_selector '[data-grouping-settings-target="groupingOptions"]'

    click_switch 'Student self-grouping'
    assert_selector '[data-grouping-settings-target="groupingOptions"]'
  end

  test 'setting and removing the end date persists through save' do
    @course.update!(grouping_closes_at: nil)
    login_as @coordinator
    visit settings_course_path(@course)
    wait_for_turbo

    click_date_toggle 'Set date'
    assert_selector 'input#course_grouping_closes_at'
    fill_in 'Close at', with: 1.month.from_now.strftime('%Y-%m-%dT%H:%M')

    click_save

    assert_text 'Course successfully updated'
    assert @course.reload.grouping_closes_at.present?

    wait_for_turbo
    click_date_toggle 'Remove date'
    click_save

    assert_text 'Course successfully updated'
    assert_nil @course.reload.grouping_closes_at
  end

  private

  def click_switch(label)
    find(%([aria-label="#{label}"]), visible: :all).execute_script('this.click()')
  end

  def click_date_toggle(label)
    find_button(label).execute_script('this.click()')
  end

  def click_save
    find('input[type="submit"][value="Save"]', match: :first).execute_script('this.click()')
  end
end
