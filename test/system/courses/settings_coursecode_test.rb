require 'application_system_test_case'

# Real-browser guard for the generate/toggle coursecode path. The widget is
# formless (ADR-0010): both Generate/Re-Generate and the toggle fire their own
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

  # The Generate button must be clicked scripted, not natively: this page's
  # headless Chrome intermittently swallows the first trusted (Selenium pointer)
  # click with no event, no request, and no navigation — reproduced both
  # sequentially and under parallel load, with native `click_button`, scripted
  # `element.click()`, and `page.execute_script`. The only reliable path is
  # `page.execute_script` *without* `wait_for_turbo` guards: Turbo already
  # marked `aria-busy` by the time the script runs, and post-click
  # `wait_for_turbo` can race the turbo-stream frame replacement, leaving the
  # assertion polling a stale DOM snapshot. This matches the pre-existing
  # behaviour that passed baseline at full parallelism.
  def click_generate
    page.execute_script("document.getElementById('regenerate-code-btn').click()")
  end

  # The toggle is a Yes/No radio pair, and a native click (Selenium pointer) on
  # a radio inside this page's form can be swallowed intermittently — dispatch
  # the click via script, which fires the same change event a real click does.
  def select_coursecode_enabled(value)
    page.execute_script(%(document.querySelector('input[name="coursecode_enabled"][value="#{value}"]').click()))
  end

  def enable_coursecode
    select_coursecode_enabled('true')
    assert_text 'Course join code settings updated'
  end

  test 'generating a coursecode persists it and reflects it back in the frame' do
    login_as @coordinator
    visit settings_course_path(@course)

    assert_nil @course.reload.coursecode

    # The code controls render only while joining via code is on.
    assert_no_selector '#regenerate-code-btn'
    enable_coursecode
    assert_selector '#regenerate-code-btn'

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

    enable_coursecode

    click_generate
    assert_text 'Course join code successfully generated'
    first_code = @course.reload.coursecode

    click_generate
    assert_text 'Course join code successfully generated'

    assert_not_equal first_code, @course.reload.coursecode
  end

  test 'toggling join code access persists and wipes the code when turned off' do
    login_as @coordinator
    visit settings_course_path(@course)

    enable_coursecode
    click_generate
    assert_text 'Course join code successfully generated'
    assert_not_nil @course.reload.coursecode

    select_coursecode_enabled('false')
    assert_text 'Course join code settings updated'
    @course.reload
    assert_not @course.coursecode_enabled
    assert_nil @course.coursecode, 'turning joining off must wipe the stored code'
    assert_no_selector '#regenerate-code-btn'

    select_coursecode_enabled('true')
    assert_text 'Course join code settings updated'
    assert @course.reload.coursecode_enabled
    assert_selector '#regenerate-code-btn'
  end

  test 'copy button copies the current join code to the clipboard' do
    login_as @coordinator
    visit settings_course_path(@course)

    enable_coursecode
    click_generate
    assert_text 'Course join code successfully generated'
    code = @course.reload.coursecode

    # Stub the clipboard so the test proves our controller wiring rather than
    # depending on headless Chrome's clipboard permission.
    page.execute_script(<<~JS)
      Object.defineProperty(navigator, 'clipboard', {
        configurable: true,
        value: { writeText: (text) => { window.__copied = text; return Promise.resolve(); } },
      });
    JS
    page.execute_script("document.getElementById('copy-code-btn').click()")

    assert_equal code, page.evaluate_script('window.__copied')
  end
end
