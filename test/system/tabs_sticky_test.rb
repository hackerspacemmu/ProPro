require 'application_system_test_case'

# Regression guard: the content-tab bar must be sticky on all three pages
# that have it (courses/show, projects/show, topics/show). rack_test can't
# check geometry, so this file drives headless Chrome, scrolls the correct
# container, and asserts the tab bar's top stays pinned.
#
# The three pages differ in *where* they scroll:
#   - courses/show: the window scrolls (no inner pane); the tab bar sticks to
#     the viewport top (0) once the shared 3.5rem header scrolls past.
#   - projects/show & topics/show: the left pane (`.overflow-y-auto`) scrolls
#     internally; the sticky tab bar pins to the top of that pane, which sits
#     at the 3.5rem (56px) header height below the viewport top.
#
# Uses `use_transactional_tests = false` for the same reason as
# mobile_overflow_test.rb: the app server thread can't see uncommitted rows.
class TabsStickyTest < ApplicationSystemTestCase
  self.use_transactional_tests = false

  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  setup do
    @course  = create(:course, use_progress_updates: true, number_of_updates: 10)
    @student = create(:user, is_staff: false)
    @student_enr = create(:enrolment, :student, user: @student, course: @course)

    @lecturer     = create(:user, is_staff: true, name: 'Alice Zane')
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

  teardown do
    return if @course.nil?

    Course.transaction do
      pids = @course.projects.where(ownership_type: :student).ids
      ProjectInstance.where(project_id: pids).find_each do |instance|
        instance.comments.delete_all
        instance.project_instance_fields.delete_all
      end
      ProjectInstance.where(project_id: pids).delete_all
      ProgressUpdate.where(project_id: pids).delete_all
      Project.where(id: pids).delete_all

      tids = @course.topics.ids
      TopicInstance.where(project_id: tids).find_each do |instance|
        instance.comments.delete_all
        instance.project_instance_fields.delete_all
      end
      TopicInstance.where(project_id: tids).delete_all
      Topic.where(id: tids).delete_all

      template = @course.project_template
      template&.project_template_fields&.delete_all
      template&.delete

      @course.enrolments.delete_all

      [@student, @lecturer, @coordinator, *@sidebar_students].compact.each do |user|
        user.sessions.delete_all
        user.otp&.delete
        user.comments.delete_all
      end

      @course.delete
      [@student, @lecturer, @coordinator, *@sidebar_students].compact.each(&:delete)
    end
  end

  def login_as(user, password: 'password')
    super
    assert_current_path root_path, wait: Capybara.default_max_wait_time * 2
  end

  def tabs_top
    page.evaluate_script(<<~JS)
      document.querySelector('[data-testid="content-tabs"]')
        .closest('.sticky')
        .getBoundingClientRect().top
    JS
  end

  test 'courses/show tab bar is sticky' do
    login_as(@student)
    visit course_path(@course)

    # courses/show scrolls at the window level. The shared header (3.5rem) is
    # sticky at viewport top 0; the tab bar pins just below it at top-[3.5rem].
    page.execute_script('window.scrollTo(0, 600)')
    sleep 0.1

    assert_in_delta 56, tabs_top, 1,
                    'courses/show tab bar should stick just below the sticky header'
  end

  test 'shared header is sticky' do
    login_as(@student)
    visit course_path(@course)

    before = page.evaluate_script(
      "document.querySelector('header').getBoundingClientRect().top"
    )
    page.execute_script('window.scrollTo(0, 600)')
    sleep 0.1
    after = page.evaluate_script(
      "document.querySelector('header').getBoundingClientRect().top"
    )

    assert_in_delta 0, before, 1, 'header should start at the top of the page'
    assert_in_delta before, after, 1, 'header should not move when the window scrolls'
  end

  test 'sidebar is sticky' do
    # The sidebar only has sticky travel room when the page is taller than the
    # viewport (its containing row must exceed the sidebar's own height, else
    # it fills the row with nowhere to pin). Its sticky top is 3.5rem so it
    # pins just below the sticky header/breadcrumb, not under it. Log in as the
    # coordinator, who sees the most Overview content, and give the course
    # enough pending proposals to make the page genuinely scroll past the
    # viewport.
    students = 20.times.map do |i|
      s = create(:user, is_staff: false, name: "Studentside #{i}")
      create(:enrolment, :student, user: s, course: @course)
      proj = create(:project, course: @course, owner: s,
                              supervisor_enrolment: @lecturer_enr, status: :pending)
      create(:project_instance, project: proj, supervisor_enrolment: @lecturer_enr,
                                created_by: s, status: :pending,
                                title: "Sidebar Proposal #{i}")
      s
    end
    @sidebar_students = students

    login_as(@coordinator)
    visit course_path(@course)

    scroll_h = page.evaluate_script('document.documentElement.scrollHeight')
    win_h = page.evaluate_script('window.innerHeight')
    assert_operator scroll_h, :>, win_h, 'test course should scroll past the viewport'

    # Scroll partway (not all the way to the bottom): at full scroll the sticky
    # sidebar is naturally clamped to the bottom of its containing row, so the
    # pinning is best observed mid-scroll. Scroll ~40% of the available range.
    scroll_to = ((scroll_h - win_h) * 0.4).round
    page.execute_script("window.scrollTo(0, #{scroll_to})")
    sleep 0.1

    assert_in_delta 56, page.evaluate_script(
      "document.getElementById('app-sidebar').getBoundingClientRect().top"
    ), 1, 'sidebar should stick just below the sticky header (top-[3.5rem])'
  end

  test 'projects/show tab bar is sticky' do
    login_as(@student)
    visit course_project_path(@course, @project)

    # The left pane is its own scroll container; scroll it internally. The
    # sticky tab bar must stay pinned to the pane top (56px below the viewport
    # top, i.e. under the fixed 3.5rem page header).
    before = tabs_top
    page.execute_script("document.querySelector('.overflow-y-auto').scrollTop = 600")
    sleep 0.1
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
    sleep 0.1
    after = tabs_top

    assert_in_delta before, after, 1,
                    'topics/show tab bar should not move when the pane scrolls'
  end
end
