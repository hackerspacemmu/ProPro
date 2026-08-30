require 'application_system_test_case'

# Real-browser guard for the generate/toggle coursecode path. The widget is
# formless (ADR-0010): Generate/Re-Generate is a data-turbo-method link (Turbo
# synthesizes a throwaway form at click time) and the toggle fires its own
# fetch() + Turbo.renderStreamMessage. Both land on the unchanged
# update_coursecode action, whose turbo streams re-render the course_code_form
# frame and the flash. rack_test cannot run the JS, so this exercises the same
# flow development browser testing could.
#
# Interactions are dispatched as scripted element.click() rather than trusted
# (Selenium pointer) clicks: on this page headless Chrome intermittently
# swallows the first trusted click with no event, no request, and no
# navigation, while a scripted click deterministically reaches Turbo's
# link/form observers — the same code a user's click runs.
#
# Turbo marks <html> aria-busy from visit start until the initial page-load
# visit completes (turbo.js visitStarted/visitCompleted), so every test waits
# for Turbo to be idle before its first interaction.
#
# Uses `use_transactional_tests = false` for the same reason as
# mobile_overflow_test.rb: a real browser hits the app on a server thread whose
# DB connection cannot see rows uncommitted in the test's transaction.
class SettingsCoursecodeTest < ApplicationSystemTestCase
  self.use_transactional_tests = false

  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  setup do
    @course = create(:course, coursecode: nil, coursecode_enabled: false)
    @coordinator = create(:enrolment, :coordinator, course: @course).user
  end

  teardown do
    return if @course.nil?

    Course.transaction do
      template = @course.project_template
      template&.project_template_fields&.delete_all
      template&.delete

      @course.enrolments.delete_all
      @course.delete

      if @coordinator
        @coordinator.sessions.delete_all
        @coordinator.otp&.delete
        @coordinator.delete
      end
    end
  end

  def login_as(user, password: 'password')
    super
    assert_current_path root_path, wait: Capybara.default_max_wait_time * 2
  end

  def wait_for_turbo
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.02 until page.evaluate_script("document.documentElement.getAttribute('aria-busy')") != 'true'
    end
  end

  def click_generate
    page.execute_script("document.getElementById('regenerate-code-btn').click()")
  end

  def toggle_enabled
    page.execute_script("document.getElementById('course_coursecode_enabled').click()")
  end

  test 'generating a coursecode persists it and reflects it back in the frame' do
    login_as @coordinator
    visit settings_course_path(@course)
    wait_for_turbo

    assert_nil @course.reload.coursecode

    click_generate
    assert_text 'Course join code successfully generated'

    code = @course.reload.coursecode
    assert_not_nil code
    assert_equal code, find('#course_code_form input[type="text"]').value
    assert_selector '#regenerate-code-btn', text: 'Re-Generate Join Code'
  end

  test 're-generating swaps the coursecode for a new one' do
    login_as @coordinator
    visit settings_course_path(@course)
    wait_for_turbo

    click_generate
    assert_text 'Course join code successfully generated'
    first_code = @course.reload.coursecode

    click_generate
    assert_text 'Course join code successfully generated'

    refute_equal first_code, @course.reload.coursecode
  end

  test 'toggling join code access persists independently of the settings form' do
    login_as @coordinator
    visit settings_course_path(@course)
    wait_for_turbo

    click_generate
    assert_text 'Course join code successfully generated'
    assert_not_nil @course.reload.coursecode

    toggle_enabled
    assert_text 'Course join code settings updated'
    assert @course.reload.coursecode_enabled

    toggle_enabled
    assert_text 'Course join code settings updated'
    refute @course.reload.coursecode_enabled
  end
end