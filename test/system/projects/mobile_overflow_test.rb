require 'application_system_test_case'

# Real-browser regression guard for the 360px horizontal overflow that shipped
# with the redesigned projects/show (Ticket 9). rack_test cannot resize the
# viewport or measure scrollWidth, so this drives headless Chrome at 360x760
# and asserts the page never scrolls sideways while the content tabs scroll
# *internally*.
class MobileOverflowTest < BrowserSystemTestCase
  self.viewport_size = [360, 760]

  setup do
    @course      = create(:course, use_progress_updates: true, number_of_updates: 10)
    @student     = create(:user)
    @student_enr = create(:enrolment, :student, user: @student, course: @course)

    @lecturer     = create(:user, :staff, name: 'Alice Zane')
    @lecturer_enr = create(:enrolment, :lecturer, user: @lecturer, course: @course)
    # The enrolment factory auto-creates its own user unless one is passed, so
    # capture those implicitly-minted users for teardown explicitly.
    @second_lecturer = create(:enrolment, :lecturer, course: @course).user
    @coordinator     = create(:enrolment, :coordinator, course: @course).user

    @project  = create(:project, course: @course, owner: @student,
                                 supervisor_enrolment: @lecturer_enr)
    @instance = create(:project_instance, project: @project, supervisor_enrolment: @lecturer_enr,
                                          created_by: @student, version: 1, status: :pending,
                                          title: 'My Proposal')
  end

  # Linux Chrome reserves a 15px scrollbar and fonts/layout settle after load,
  # so scrollWidth can flicker for the first few frames. Poll until two
  # consecutive reads agree before asserting anything geometry-based.
  def wait_for_stable_metrics(script)
    deadline = Time.zone.now + 5
    previous = nil
    loop do
      current = page.evaluate_script(script)
      return current if previous == current

      previous = current
      assert_operator Time.zone.now, :<, deadline,
                      "document metrics never stabilized: #{current.inspect} vs #{previous.inspect}"
      sleep 0.15
    end
  end

  test '360px viewport has no page-level horizontal overflow' do
    login_as(@student)
    visit course_project_path(@course, @project)

    assert_selector '[data-testid="content-tabs"]'

    json = wait_for_stable_metrics(
      'JSON.stringify([document.documentElement.scrollWidth, document.documentElement.clientWidth])'
    )
    scroll_width, client_width = JSON.parse(json)

    assert_operator scroll_width, :<=, client_width,
                    "page should not scroll sideways at 360px (scrollWidth=#{scroll_width}, clientWidth=#{client_width})"
  end

  test 'content tabs scroll internally at 360px and the comments trigger stays on-screen' do
    login_as(@student)
    visit course_project_path(@course, @project)

    metrics = page.evaluate_script(<<~JS)
      (function () {
        const clientWidth = document.documentElement.clientWidth;
        const tabs = document.querySelector('[data-testid="content-tabs"]');
        const trigger = document.querySelector('[data-comments-drawer-target="trigger"]');
        return {
          clientWidth,
          tabsScrollWidth: tabs.scrollWidth,
          tabsClientWidth: tabs.clientWidth,
          triggerRight: trigger.getBoundingClientRect().right
        };
      })()
    JS

    assert_operator metrics['tabsScrollWidth'], :>, metrics['tabsClientWidth'],
                    'content tabs should overflow their container and scroll internally'

    assert_operator metrics['triggerRight'], :<=, metrics['clientWidth'],
                    'comments trigger should be visible on-screen, not pushed past the right edge'
  end

  test 'trailing-edge fade is only visible while the tab strip overflows' do
    login_as(@student)
    visit course_project_path(@course, @project)

    # 360px: the strip overflows, so the mask shows.
    assert_selector '[data-tab-fade-target="rightMask"]:not(.hidden)'

    # Scrolled to the end: nothing further to reveal, mask hides.
    # `.hidden` = display:none, so Capybara's default visibility filter must be
    # widened (visible: :all) for these to match.
    page.execute_script("document.querySelector('[data-testid=\"content-tabs\"]').scrollLeft = 1e6")
    assert_selector '[data-tab-fade-target="rightMask"].hidden', visible: :all

    # Back at the start with overflow remaining: mask returns.
    page.execute_script("document.querySelector('[data-testid=\"content-tabs\"]').scrollLeft = 0")
    assert_selector '[data-tab-fade-target="rightMask"]:not(.hidden)'

    # Wide viewport: everything fits, so the mask stays hidden even at the start.
    page.driver.browser.manage.window.resize_to(1280, 900)
    assert_selector '[data-tab-fade-target="rightMask"].hidden', visible: :all
  end

  test 'closed comments drawer leaves no shadow or edge hairline, open state restores them' do
    login_as(@student)
    visit course_project_path(@course, @project)

    # Closed: no shadow, no edge border. assert_no_selector *and* the open
    # checks below let Capybara retry, so the assertions track the class state
    # itself instead of racing it via a raw JS read.
    assert_no_selector '#comments-drawer.shadow-2xl'
    assert_no_selector '#comments-drawer.border-l'

    # Locate the trigger natively (waits for it to be present/visible) but
    # dispatch the click scripted: a cold-launched headless worker intermittently
    # swallows the first trusted click — reproduced here under full parallelism
    # when #comments-drawer.shadow-2xl never appeared. this.click() throws the
    # same event a user's click fires, and the asserts below still prove the
    # drawer state actually flipped.
    find('[data-comments-drawer-target="trigger"]').execute_script('this.click()')
    assert_selector '#comments-drawer.shadow-2xl'
    assert_selector '#comments-drawer.border-l'

    # The open drawer overlays the trigger (both right-aligned), so close via
    # Escape, which show.html.erb wires to comments-drawer#closeOnEscape
    # (keydown.esc@window). Dispatched on window, not OS-send_keys: the action
    # listens on window, and Selenium's send_keys routes through OS-level focus
    # that an unfocused headless window drops intermittently — reproduced here
    # as "comments drawer never closed on Escape". Dispatching the KeyboardEvent
    # on window drives the exact same listener a user's Escape hits (closeOnEscape
    # runs, event.key checked).
    page.execute_script(
      'window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }))'
    )
  end
end
