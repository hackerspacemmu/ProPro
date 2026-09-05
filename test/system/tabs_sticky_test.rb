require 'application_system_test_case'

# Regression guard: the content-tab bar must be sticky on all three pages
# that have it (courses/show, projects/show, topics/show). rack_test can't
# check geometry, so this file drives headless Chrome, scrolls the correct
# container, and asserts the tab bar's top stays pinned.
#
# All three pages share the same capped-height shell: <main> is fixed at
# calc(100vh - 3.5rem), so the WINDOW itself never scrolls — each page owns
# its overflow internally, and the sticky tab bar pins to the top of its
# scroll pane (56px below the viewport top, directly under the sticky shared
# header):
#   - courses/show: <main> is the scroll pane itself (overflow-y-auto).
#   - projects/show & topics/show: the left pane (`.overflow-y-auto`) scrolls
#     internally inside <main>.
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

  def scroll_main(pixels)
    page.execute_script("document.querySelector('main').scrollTop = #{pixels}")
    sleep 0.1
  end

  # Populates the course with enough pending proposals to make the Overview
  # genuinely overflow its scroll pane, and the sidebar a coordinator sees
  # populate with content.
  def seed_tall_overview
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
    assert_in_delta 56, tabs_top, 1,
                    'courses/show tab bar should pin to the top of <main> (under the sticky shared header)'
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

  test 'sidebar stays pinned while the pane scrolls' do
    seed_tall_overview

    login_as(@coordinator)
    visit course_path(@course)

    # The capped-height shell means the window itself never scrolls; all the
    # overflow is internal to <main>. Assert that invariant, then confirm the
    # sidebar stays put (pinned below the sticky header) while <main> scrolls.
    scroll_h = page.evaluate_script('document.documentElement.scrollHeight')
    win_h = page.evaluate_script('window.innerHeight')
    assert_operator scroll_h, :<=, win_h,
                    'window should not scroll; <main> owns the scroll'

    scroll_main(600)
    assert_in_delta 56, page.evaluate_script(
      "document.getElementById('app-sidebar').getBoundingClientRect().top"
    ), 1, 'sidebar should stay pinned below the sticky header while <main> scrolls'
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
