require 'application_system_test_case'

# Real-browser guard for the ?tab= persistence on courses/show. rack_test cannot
# run the Stimulus tabs controller (which writes the active tab key back into
# the URL via history.replaceState on click), so this drives headless Chrome:
# it clicks a tab, confirms the URL gains ?tab=, reloads, and asserts the same
# tab is still active.
#
# Uses `use_transactional_tests = false` for the same reason as
# mobile_overflow_test.rb: a real browser hits the app on a server thread whose
# DB connection cannot see rows uncommitted in the test's transaction.
class CourseTabPersistenceTest < ApplicationSystemTestCase
  self.use_transactional_tests = false

  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  setup do
    @course = create(:course)
    @coordinator = create(:enrolment, :coordinator, course: @course).user
  end

  teardown do
    return if @course.nil?

    Course.transaction do
      template = @course.project_template
      template&.project_template_fields&.delete_all
      template&.delete

      @course.enrolments.delete_all

      @coordinator.sessions.delete_all
      @coordinator.otp&.delete

      @course.delete
      @coordinator.delete
    end
  end

  def login_as(user, password: 'password')
    super
    assert_current_path root_path, wait: Capybara.default_max_wait_time * 2
  end

  # Headless Chrome intermittently drops synthetic native clicks dispatched right
  # after load (a driver-level quirk we've seen ~50% of the time), while JS-
  # dispatched clicks always work. This test asserts persistence semantics — the
  # tab switch, the ?tab= write-back, and the reload — so it dispatches a real
  # DOM click through the button instead of a native one.
  def click_tab(name)
    find_button(name).evaluate_script('this.click()')
    assert_selector 'button[aria-selected="true"]', text: name
  end

  test 'clicking a tab writes ?tab= and it survives a reload' do
    login_as @coordinator
    visit course_path(@course)

    click_tab 'Topics'
    assert_current_path course_path(@course, tab: 'topics')

    visit current_url
    assert_selector 'button[aria-selected="true"]', text: 'Topics'
  end
end
