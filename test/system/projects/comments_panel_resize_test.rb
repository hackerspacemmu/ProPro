require 'application_system_test_case'

# The drag-resize of the comments panel (#comments-drawer) is the one part of
# the feature that needs a real browser: it is a Stimulus controller moving a
# CSS custom property, and rack_test runs no JavaScript. Everything else is
# covered without a browser - the server-side width in
# test/helpers/application_helper_test.rb, the handle's wiring in
# test/system/projects/project_show_responsive_test.rb.
class CommentsPanelResizeTest < BrowserSystemTestCase
  setup do
    # The width lives in a cookie, so the drag has to start from a known one.
    page.driver.browser.manage.delete_all_cookies

    @course      = create(:course)
    @student     = create(:user)
    @student_enr = create(:enrolment, :student, user: @student, course: @course)

    @lecturer     = create(:user, :staff, name: 'Alice Zane')
    @lecturer_enr = create(:enrolment, :lecturer, user: @lecturer, course: @course)
    create(:enrolment, :lecturer, course: @course)
    create(:enrolment, :coordinator, course: @course)

    @project = create(:project, course: @course, owner: @student,
                                supervisor_enrolment: @lecturer_enr)
    create(:project_instance, project: @project, supervisor_enrolment: @lecturer_enr,
                              created_by: @student, version: 1, status: :pending,
                              title: 'My Proposal')
  end

  test 'dragging the handle widens the panel and the width survives a reload' do
    login_as(@student)
    visit course_project_path(@course, @project)
    wait_for_turbo

    start_width = panel_width
    drag_handle_left(120)

    assert_in_delta start_width + 120, panel_width, 1

    # A full reload comes back at the saved width: the server read the cookie
    # and rendered --comments-w into the markup.
    visit current_url
    wait_for_turbo

    assert_in_delta start_width + 120, panel_width, 1
  end

  def panel_width
    page.evaluate_script('document.getElementById("comments-drawer").getBoundingClientRect().width')
  end

  # Drags the handle left by delta pixels with synthetic pointer events, the
  # way the controller sees them: pointerdown, pointermove, pointerup on the
  # handle. A synthetic event has no pointer to capture, which the controller
  # tolerates - it listens for the move on the handle itself.
  def drag_handle_left(delta)
    page.execute_script(<<~JS, delta)
      const delta = arguments[0];
      const handle = document.querySelector('[data-comments-panel-target="handle"]');
      const rect = handle.getBoundingClientRect();
      const x = rect.left + rect.width / 2;
      const y = rect.top + rect.height / 2;
      const shared = { bubbles: true, cancelable: true, pointerId: 1, isPrimary: true };
      handle.dispatchEvent(new PointerEvent('pointerdown',
        Object.assign({}, shared, { clientX: x, clientY: y, button: 0, buttons: 1 })));
      handle.dispatchEvent(new PointerEvent('pointermove',
        Object.assign({}, shared, { clientX: x - delta, clientY: y, button: -1, buttons: 1 })));
      handle.dispatchEvent(new PointerEvent('pointerup',
        Object.assign({}, shared, { clientX: x - delta, clientY: y, button: 0, buttons: 0 })));
    JS
  end
end
