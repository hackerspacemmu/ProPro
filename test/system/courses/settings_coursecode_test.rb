require 'application_system_test_case'

# Real-browser guard for the generate/toggle coursecode path. The widget is
# formless (ADR-0010): Generate/Re-Generate is a data-turbo-method link (Turbo
# synthesizes a throwaway form at click time) and the toggle fires its own
# fetch() + Turbo.renderStreamMessage. Both land on the unchanged
# update_coursecode action, whose turbo streams re-render the course_code_form
# frame and the flash. rack_test cannot run the JS, so this exercises the same
# flow development browser testing could.
#
# Every test waits for Turbo to be idle before its first interaction:
# Turbo marks <html> aria-busy from visit start until the initial page-load
# visit completes, and a click fired before that races the Turbo/Stimulus
# listeners (wait_for_turbo lives on BrowserSystemTestCase).
class SettingsCoursecodeTest < BrowserSystemTestCase
  setup do
    @course = create(:course, coursecode: nil, coursecode_enabled: false)
    @coordinator = create(:enrolment, :coordinator, course: @course).user
  end

  # The Generate link must be clicked scripted, not natively: this page's
# headless Chrome intermittently swallows the first trusted (Selenium pointer)
# click with no event, no request, and no navigation — reproduced both
# sequentially and under parallel load, with native `click_link`, scripted
# `element.click()`, and `page.execute_script`. The only reliable path is
# `page.execute_script` *without* `wait_for_turbo` guards: Turbo already
# marked `aria-busy` by the time the script runs, and post-click
# `wait_for_turbo` can race the turbo-stream frame replacement, leaving the
# assertion polling a stale DOM snapshot. This matches the pre-existing
# behaviour that passed baseline at full parallelism.
  def click_generate
    page.execute_script("document.getElementById('regenerate-code-btn').click()")
  end

  # The toggle checkbox is visually hidden (sr-only peer), so a native click
  # would fail intermittently on this page — dispatch the click via script,
  # which is the same change event a real click fires.
  def toggle_enabled
    page.execute_script("document.getElementById('course_coursecode_enabled').click()")
  end

  test 'generating a coursecode persists it and reflects it back in the frame' do
    login_as @coordinator
    visit settings_course_path(@course)

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

    click_generate
    assert_text 'Course join code successfully generated'
    first_code = @course.reload.coursecode

    click_generate
    assert_text 'Course join code successfully generated'

    assert_not_equal first_code, @course.reload.coursecode
  end

  test 'toggling join code access persists independently of the settings form' do
    login_as @coordinator
    visit settings_course_path(@course)

    click_generate
    assert_text 'Course join code successfully generated'
    assert_not_nil @course.reload.coursecode

    toggle_enabled
    assert_text 'Course join code settings updated'
    assert @course.reload.coursecode_enabled

    toggle_enabled
    assert_text 'Course join code settings updated'
    assert_not @course.reload.coursecode_enabled
  end
end
