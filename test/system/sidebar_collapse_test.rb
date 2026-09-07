require 'application_system_test_case'

# Real-browser guard for the desktop sidebar rail-collapse (data-collapsed +
# CSS variants + propro_sidebar_rail_collapsed cookie). rack_test can't run the
# Stimulus controller, can't resize the viewport, and reports nothing about
# geometry, so this drives headless Chrome at a desktop viewport, collapses the
# rail, and asserts width + cookie + reload persistence, then shrinks to a
# mobile viewport and confirms the off-canvas drawer is byte-for-byte unaffected.
#
# Uses `use_transactional_tests = false` for the same reason as
# mobile_overflow_test.rb / course_tab_persistence_test.rb: a real browser hits
# the app on a server thread whose DB connection can't see uncommitted rows in
# the test's transaction.
class SidebarCollapseTest < ApplicationSystemTestCase
  self.use_transactional_tests = false

  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  def setup
    # Tests share one browser session: reset the viewport AND drop the
    # sidebar rail-collapse cookie so one test's collapsed state can't leak
    # into the start of another.
    page.driver.browser.manage.window.resize_to(1280, 900)
    page.driver.browser.manage.delete_all_cookies

    @course  = create(:course)
    @student = create(:user)
    create(:enrolment, :student, user: @student, course: @course)
  end

  def teardown
    return if @course.nil?

    Course.transaction do
      template = @course.project_template
      template&.project_template_fields&.delete_all
      template&.delete

      @course.enrolments.delete_all

      @student.sessions.delete_all
      @student.otp&.delete

      @course.delete
      @student.delete
    end
  end

  def login_as(user, password: 'password')
    super
    assert_current_path root_path, wait: Capybara.default_max_wait_time * 2
  end

  # Headless Chrome drops ~50% of native clicks right after load (the same
  # driver quirk course_tab_persistence_test.rb works around); a dispatched
  # DOM click always lands.
  def click_toggle
    find('[data-sidebar-target="toggleButton"]').evaluate_script('this.click()')
  end

  def sidebar_width
    page.evaluate_script('document.getElementById("app-sidebar").getBoundingClientRect().width')
  end

  # window.resize_to commits asynchronously in ChromeDriver; a click fired
  # while the old viewport still holds hits the wrong breakpoint branch in the
  # controller. Wait for the media query to actually flip before interacting
  # after any resize.
  def wait_for_breakpoint(desktop:)
    deadline = Time.zone.now + 5
    loop do
      matches = page.evaluate_script('window.matchMedia("(min-width: 1024px)").matches')
      return if matches == desktop

      assert_operator Time.zone.now, :<, deadline,
                      "viewport never reached #{desktop ? 'desktop' : 'mobile'} breakpoint"
      sleep 0.1
    end
  end

  # The rail animates over ~200ms; poll until two consecutive reads agree
  # before asserting any width (same idiom as mobile_overflow_test.rb).
  def wait_for_sidebar_width
    deadline = Time.zone.now + 5
    previous = nil
    loop do
      current = sidebar_width
      return current if previous == current

      previous = current
      assert_operator Time.zone.now, :<, deadline,
                      'sidebar width never settled (stuck animating?)'
      sleep 0.1
    end
  end

  def rail_cookie
    page.evaluate_script('document.cookie')
  end

  def aria_expanded
    find('[data-sidebar-target="toggleButton"]')['aria-expanded']
  end

  test 'desktop collapse toggles the rail, persists across reload, and never leaks into mobile' do
    login_as @student
    visit course_path(@course)

    # Default state: expanded rail, 280px, rail reflected in aria-expanded.
    wait_for_breakpoint(desktop: true)
    assert_in_delta 280, sidebar_width, 1
    assert_equal 'true', aria_expanded

    click_toggle
    assert_in_delta 72, wait_for_sidebar_width, 1
    assert_includes rail_cookie, 'propro_sidebar_rail_collapsed=true'
    assert_equal 'false', aria_expanded

    # Server-side read: a full reload comes back collapsed — no wrong-width flash.
    visit current_url
    assert_in_delta 72, wait_for_sidebar_width, 1

    # Same cookie, mobile viewport: the drawer is governed purely by the
    # translate/backdrop mechanism; data-collapsed is inert below lg.
    page.driver.browser.manage.window.resize_to(600, 800)
    wait_for_breakpoint(desktop: false)
    assert_in_delta 280, wait_for_sidebar_width, 1
    assert_includes find('#app-sidebar')['class'], '-translate-x-full'

    click_toggle
    assert_not_includes find('#app-sidebar')['class'], '-translate-x-full'
    assert_equal 'true', aria_expanded
    assert_selector '[data-sidebar-target="backdrop"]:not(.hidden)'

    # Close via the backdrop (deterministic; Escape-close is pre-existing and
    # covered by mobile_overflow_test.rb). Dispatch like click_toggle: headless
    # Chrome drops ~50% of native clicks.
    find('[data-sidebar-target="backdrop"]').evaluate_script('this.click()')
    assert_includes find('#app-sidebar')['class'], '-translate-x-full'
    assert_selector '[data-sidebar-target="backdrop"].hidden', visible: :all
  end

  test 'every sidebar nav item has an accessible name in both states' do
    login_as @student
    visit course_path(@course)

    items = page.all('#app-sidebar a, #app-sidebar button', visible: :all)
    labels = items.map { |el| el['aria-label'] }

    assert labels.none?(&:blank?), "every nav item needs an aria-label, got: #{labels.inspect}"
    assert_includes labels, 'Home'
    assert_includes labels, @course.course_name
    assert_includes labels, 'Edit profile'
    assert_includes labels, 'Log out'
  end
end
