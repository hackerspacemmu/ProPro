require 'application_system_test_case'

# Real-browser guard for route-per-tab navigation on courses/show (ADR 0019).
# rack_test can assert hrefs but cannot exercise Turbo Drive's history, so this
# drives headless Chrome: clicking a tab link must land on that tab's own URL
# with it marked current, and browser back must restore Overview — the URL is
# the source of truth now, so there is no persist cookie to check.
class CourseTabNavigationTest < BrowserSystemTestCase
  setup do
    @course = create(:course)
    @coordinator = create(:enrolment, :coordinator, course: @course).user
  end

  # Locate the link natively (waits for it to be present/visible) but dispatch
  # the click scripted: a freshly-launched headless Chrome worker intermittently
  # swallows the first trusted click (reproduced under full parallelism here —
  # the tab stayed on Overview with no event and no navigation). this.click()
  # deterministically reaches Turbo Drive, which is the same code a user's
  # click runs. The path/aria assertions below still verify the navigation
  # genuinely happened.
  def click_tab(name)
    wait_for_turbo
    find_link(name).execute_script('this.click()')
    wait_for_turbo
  end

  def current_tab
    page.evaluate_script(
      "document.querySelector('[data-testid=\"content-tabs\"] a[aria-current=\"page\"]')?.textContent.trim()"
    )
  end

  test 'clicking a tab link navigates to its route and browser back restores Overview' do
    login_as @coordinator
    visit course_path(@course)
    assert_equal 'Overview', current_tab

    click_tab 'Topics'
    assert_current_path course_topics_path(@course)
    assert_equal 'Topics', current_tab

    page.go_back
    wait_for_turbo
    assert_current_path course_path(@course)
    assert_equal 'Overview', current_tab
  end
end
