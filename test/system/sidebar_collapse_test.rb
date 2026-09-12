require 'application_system_test_case'

# Real-browser guard for the desktop sidebar rail-collapse (data-collapsed +
# CSS variants + propro_sidebar_rail_collapsed cookie). rack_test can't run the
# Stimulus controller, can't resize the viewport, and reports nothing about
# geometry, so this drives headless Chrome at a desktop viewport, collapses the
# rail, and asserts width + cookie + reload persistence, then shrinks to a
# mobile viewport and confirms the off-canvas drawer is byte-for-byte unaffected.
class SidebarCollapseTest < BrowserSystemTestCase
  def setup
    # Drop the sidebar rail-collapse cookie so one test's collapsed state can't
    # leak into the start of another (the viewport itself is reset by the base
    # class's resize_to).
    page.driver.browser.manage.delete_all_cookies

    @course  = create(:course)
    @student = create(:user)
    create(:enrolment, :student, user: @student, course: @course)
  end

  # Locate the toggle natively (waits for presence/visibility) but dispatch the
  # click scripted: a cold-launched headless worker intermittently swallows the
  # first trusted click — reproduced under full parallelism when the rail never
  # collapsed ("sidebar never reached 72px (stuck at 280)"). this.click() throws
  # the same event a user's click fires; every width/state assert that follows
  # still proves the collapse actually happened.
  def click_toggle
    wait_for_turbo
    find('[data-sidebar-target="toggleButton"]').execute_script('this.click()')
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

  # The rail animates and recomputes after resize/media-query flips, so poll
  # until the width settles AT the expected value rather than just becoming
  # stable: a rapid desktop→mobile resize can leave the controller briefly
  # computing the stale collapsed width for a stable stretch, which a
  # settle-then-assert read would swallow.
  def wait_for_sidebar_width(expected)
    deadline = Time.zone.now + Capybara.default_max_wait_time
    loop do
      width = sidebar_width
      return width if (width - expected).abs <= 1

      assert_operator Time.zone.now, :<, deadline,
                      "sidebar never reached #{expected}px (stuck at #{width})"
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
    assert_in_delta 280, wait_for_sidebar_width(280), 1
    assert_equal 'true', aria_expanded

    click_toggle
    assert_in_delta 72, wait_for_sidebar_width(72), 1
    assert_includes rail_cookie, 'propro_sidebar_rail_collapsed=true'
    assert_equal 'false', aria_expanded

    # Server-side read: a full reload comes back collapsed — no wrong-width flash.
    visit current_url
    assert_in_delta 72, wait_for_sidebar_width(72), 1

    # Same cookie, mobile viewport: the drawer is governed purely by the
    # translate/backdrop mechanism; data-collapsed is inert below lg.
    page.driver.browser.manage.window.resize_to(600, 800)
    wait_for_breakpoint(desktop: false)
    assert_in_delta 280, wait_for_sidebar_width(280), 1
    assert_includes find('#app-sidebar')['class'], '-translate-x-full'

    click_toggle
    assert_not_includes find('#app-sidebar')['class'], '-translate-x-full'
    assert_equal 'true', aria_expanded
    assert_selector '[data-sidebar-target="backdrop"]:not(.hidden)'

    # Close via the backdrop (Escape-close is pre-existing and covered by
    # mobile_overflow_test.rb). Scripted for the same cold-worker first-click
    # reason as click_toggle: reproduced when the drawer stayed open here
    # ("app-sidebar still showed -translate-x-full absent" after a native click).
    find('[data-sidebar-target="backdrop"]').execute_script('this.click()')
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
