require 'application_system_test_case'

# Regression guard: the content-tab bar must be sticky on all three pages
# that have it (courses/show, projects/show, topics/show). rack_test can't
# check geometry, so this drives headless Chrome, scrolls the correct
# container, and asserts the tab bar's top stays pinned.
#
# All three pages share the same capped-height shell: <main> is fixed at
# calc(100vh - 3.5rem), so the WINDOW itself never scrolls — each page owns
# its overflow internally, and the sticky tab bar pins to the top of its
# scroll pane (under the sticky shared header):
#   - courses/show: <main> is the scroll pane itself (overflow-y-auto).
#   - projects/show & topics/show: the left pane (`.overflow-y-auto`) scrolls
#     internally inside <main>.
#
# Wherever possible these tests compare before/after geometry rather than
# hardcoded pixel offsets, so they hold at any viewport the driver resolves to.
class TabsStickyTest < BrowserSystemTestCase
  setup do
    @course  = create(:course, use_progress_updates: true, number_of_updates: 10)
    @student = create(:user)
    @student_enr = create(:enrolment, :student, user: @student, course: @course)

    @lecturer     = create(:user, :staff, name: 'Alice Zane')
    @lecturer_enr = create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @coordinator = create(:enrolment, :coordinator, course: @course).user

    @project  = create(:project, course: @course, owner: @student,
                                 supervisor_enrolment: @lecturer_enr)
    @instance = create(:project_instance, project: @project,
                                          supervisor_enrolment: @lecturer_enr,
                                          created_by: @student,
                                          version: 1, status: :pending,
                                          title: 'Test Proposal')

    @topic          = create(:topic, course: @course, owner: @lecturer)
    @topic_instance = create(:topic_instance, topic: @topic,
                                              created_by: @lecturer,
                                              version: 1, status: :pending,
                                              title: 'Test Topic')
  end

  def tabs_top
    page.evaluate_script(<<~JS)
      document.querySelector('[data-testid="content-tabs"]')
        .closest('.sticky')
        .getBoundingClientRect().top
    JS
  end

  # Assigning scrollTop and reading it in separate evaluate round-trips races
  # the browser's next-frame style commit, so poll until the scroll actually
  # lands. The pane scrolls to whatever its content allows (scrollTop clamps at
  # the max scroll) — the pin assertions only care that it MOVED.
  def scroll_main(pixels)
    page.execute_script("document.querySelector('main').scrollTop = #{pixels}")
    deadline = Time.zone.now + Capybara.default_max_wait_time
    loop do
      top = page.evaluate_script("document.querySelector('main').scrollTop")
      return if top.positive?

      assert_operator Time.zone.now, :<, deadline,
                      "main never scrolled from #{pixels} (stuck at #{top})"
      sleep 0.02
    end
  end

  # Populates the course with enough pending proposals to make the Overview
  # genuinely overflow its scroll pane, and the sidebar a coordinator sees
  # populate with content.
  def seed_tall_overview
    students = 20.times.map do |i|
      s = create(:user, name: "Studentside #{i}")
      create(:enrolment, :student, user: s, course: @course)
      proj = create(:project, course: @course, owner: s,
                              supervisor_enrolment: @lecturer_enr, status: :pending)
      create(:project_instance, project: proj, supervisor_enrolment: @lecturer_enr,
                                created_by: s, status: :pending,
                                title: "Sidebar Proposal #{i}")
      s
    end
    @sidebar_students = students
  end

  test 'courses/show tab bar stays pinned to the top of its pane' do
    seed_tall_overview
    login_as(@coordinator)
    visit course_path(@course)

    # courses/show's <main> is the scroll pane itself; the Overview content
    # must genuinely overflow it for the pinning to be exercised.
    assert page.evaluate_script(
      "document.querySelector('main').scrollHeight > document.querySelector('main').clientHeight"
    ), 'Overview content should overflow <main> for the tab bar to pin'

    scroll_main(600)
    main_top = page.evaluate_script(
      "document.querySelector('main').getBoundingClientRect().top"
    )
    assert_in_delta main_top, tabs_top, 1,
                    'courses/show tab bar should pin to the top of <main> (under the sticky shared header)'
  end

  test 'shared header is sticky' do
    login_as(@student)
    visit course_path(@course)

    before = page.evaluate_script(
      "document.querySelector('header').getBoundingClientRect().top"
    )
    page.execute_script('window.scrollTo(0, 600)')
    after = page.evaluate_script(
      "document.querySelector('header').getBoundingClientRect().top"
    )

    assert_in_delta 0, before, 1, 'header should start at the top of the page'
    assert_in_delta before, after, 1, 'header should not move when the window scrolls'
  end

  test 'sidebar stays pinned while the pane scrolls' do
    seed_tall_overview

    login_as(@coordinator)
    visit course_path(@course)

    # The capped-height shell means <main> owns the overflow internally. Read
    # the sidebar's position before and after the pane scrolls — it must not
    # move, wherever it pins under the header. Viewport-independent, matching
    # the before/after idiom the other tests in this file use.
    before = page.evaluate_script(
      "document.getElementById('app-sidebar').getBoundingClientRect().top"
    )
    scroll_main(600)
    after = page.evaluate_script(
      "document.getElementById('app-sidebar').getBoundingClientRect().top"
    )

    assert_in_delta before, after, 2,
                    'sidebar should stay pinned while <main> scrolls'
  end

  test 'projects/show tab bar is sticky' do
    login_as(@student)
    visit course_project_path(@course, @project)

    # The left pane is its own scroll container; scroll it internally. The
    # sticky tab bar must stay pinned to the pane top (under the fixed 3.5rem
    # page header).
    before = tabs_top
    page.execute_script("document.querySelector('.overflow-y-auto').scrollTop = 600")
    after = tabs_top

    assert_in_delta before, after, 1,
                    'projects/show tab bar should not move when the pane scrolls'
  end

  test 'topics/show tab bar is sticky' do
    # The topic is owned by the lecturer and pending, so a student can't view
    # it (TopicPolicy#show?: coordinator || own_topic || approved). Log in as
    # the owning lecturer.
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    before = tabs_top
    page.execute_script("document.querySelector('.overflow-y-auto').scrollTop = 600")
    after = tabs_top

    assert_in_delta before, after, 1,
                    'topics/show tab bar should not move when the pane scrolls'
  end
end
