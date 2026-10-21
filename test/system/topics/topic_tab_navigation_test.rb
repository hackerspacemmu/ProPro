require 'application_system_test_case'

# Real-browser guard for route-per-tab navigation on topics/show. rack_test can
# assert hrefs but cannot exercise Turbo Drive's history, so this drives
# headless Chrome: clicking a tab link must land on that tab's own URL with it
# marked current, and browser back must restore Topic Details.
class TopicTabNavigationTest < BrowserSystemTestCase
  setup do
    @course = create(:course)
    @lecturer = create(:user, :staff)
    create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @topic = create(:topic, course: @course, owner: @lecturer)
    create(:topic_instance, topic: @topic, created_by: @lecturer, version: 1, status: :pending)
  end

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

  test 'clicking a tab link navigates to its route and browser back restores Topic Details' do
    login_as @lecturer
    visit course_topic_path(@course, @topic)
    assert_equal 'Topic Details', current_tab

    click_tab 'Compare Versions'
    assert_current_path course_topic_version_comparison_path(@course, @topic)
    assert_equal 'Compare Versions', current_tab

    page.go_back
    wait_for_turbo
    assert_current_path course_topic_path(@course, @topic)
    assert_equal 'Topic Details', current_tab
  end
end
