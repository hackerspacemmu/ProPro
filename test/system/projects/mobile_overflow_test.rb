require 'application_system_test_case'

# Real-browser regression guard for the 360px horizontal overflow that shipped
# with the redesigned projects/show (Ticket 9). rack_test cannot resize the
# viewport or measure scrollWidth, so this file drives headless Chrome at
# 360x760 and asserts the page never scrolls sideways while the content tabs
# scroll *internally*.
#
# Uses `use_transactional_tests = false`: with a real browser the app runs on a
# server thread whose DB connection cannot see rows uncommitted in the test's
# transaction, so FactoryBot records must be committed for the login to work.
class MobileOverflowTest < ApplicationSystemTestCase
  self.use_transactional_tests = false

  driven_by :selenium, using: :headless_chrome, screen_size: [360, 760]

  setup do
    # Tests share one browser session; a wide viewport from a previous test
    # (e.g. the fade test's resize_to) would let tabs fit and hide the trigger.
    page.driver.browser.manage.window.resize_to(360, 760)

    @course      = create(:course, use_progress_updates: true, number_of_updates: 10)
    @student     = create(:user, is_staff: false)
    @student_enr = create(:enrolment, :student, user: @student, course: @course)

    @lecturer     = create(:user, is_staff: true, name: 'Alice Zane')
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

  teardown do
    return if @course.nil?

    # With use_transactional_tests = false nothing rolls back, and the course
    # factory's project template carries callback-protected fields (a title
    # field refuses to destroy), so we delete records directly in FK order
    # instead of relying on dependent callbacks.
    Course.transaction do
      pids = @course.projects.ids
      ProjectInstance.where(project_id: pids).find_each do |instance|
        instance.comments.delete_all
        instance.project_instance_fields.delete_all
      end
      ProjectInstance.where(project_id: pids).delete_all
      ProgressUpdate.where(project_id: pids).delete_all
      Project.where(id: pids).delete_all

      template = @course.project_template
      template&.project_template_fields&.delete_all
      template&.delete

      @course.enrolments.delete_all

      [@student, @lecturer, @second_lecturer, @coordinator].compact.each do |user|
        user.sessions.delete_all
        user.otp&.delete
        user.comments.delete_all
      end

      @course.delete
      [@student, @lecturer, @second_lecturer, @coordinator].compact.each(&:delete)
    end
  end

  def login_as(user, password: 'password')
    super
    # Turbo submits via fetch; wait deterministically for the post-login
    # redirect (root_url) instead of racing the navigation.
    assert_current_path root_path, wait: Capybara.default_max_wait_time * 2
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

    panel_flags = 'JSON.stringify((el => ({ shadow: el.classList.contains("shadow-2xl"), border: el.classList.contains("border-l") }))(document.getElementById("comments-drawer")))'
    panel_right = 'document.getElementById("comments-drawer").getBoundingClientRect().right'
    assert_flags = lambda do |shadow, border|
      flags = JSON.parse(page.evaluate_script(panel_flags))
      assert_equal shadow, flags['shadow'], 'drawer shadow-2xl state'
      assert_equal border, flags['border'], 'drawer border-l state'
    end

    assert_flags.call(false, false) # closed: no shadow, no edge border

    find('[data-comments-drawer-target="trigger"]').click
    wait_for_stable_metrics(panel_right)
    assert_flags.call(true, true) # open: shadow + edge border restored

    # The open drawer overlays the trigger (both right-aligned), so close via
    # Escape, which show.html.erb wires to comments-drawer#closeOnEscape.
    page.send_keys(:escape)
    wait_for_stable_metrics(panel_right)
    assert_flags.call(false, false) # closed again
  end
end
