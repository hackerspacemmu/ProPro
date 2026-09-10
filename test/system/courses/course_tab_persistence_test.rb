require 'application_system_test_case'

# Real-browser guard for the per-course tab cookie on courses/show. rack_test
# cannot run the Stimulus tabs controller, so this drives headless Chrome: it
# clicks a tab, confirms the persist cookie was written, and reloads to assert
# the same tab is still active. (Persistence is cookie-based — commit f6d4c6cf
# moved it off history.replaceState/#?tab=, which the server never read anyway.)
class CourseTabPersistenceTest < BrowserSystemTestCase
  setup do
    @course = create(:course)
    @coordinator = create(:enrolment, :coordinator, course: @course).user
  end

  # Locate the button natively (waits for it to be present/visible) but dispatch
  # the click scripted: a freshly-launched headless Chrome worker intermittently
  # swallows the first trusted click (reproduced under full parallelism here —
  # the tab stayed on Overview with no event and no navigation). this.click()
  # deterministically reaches the tabs Stimulus controller, which is the same
  # code a user's click runs. The assert_selector below still verifies the tab
  # genuinely switched.
  def click_tab(name)
    wait_for_turbo
    find_button(name).execute_script('this.click()')
    assert_selector 'button[aria-selected="true"]', text: name
  end

  def tab_cookie
    page.evaluate_script('document.cookie')
  end

  test 'clicking a tab writes the persist cookie and it survives a reload' do
    login_as @coordinator
    visit course_path(@course)

    click_tab 'Topics'
    assert_includes tab_cookie, "propro_tab_course_#{@course.id}=topics"

    visit current_url
    assert_selector 'button[aria-selected="true"]', text: 'Topics'
  end
end
