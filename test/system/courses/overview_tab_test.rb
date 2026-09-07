require 'application_system_test_case'

# State coverage for the Overview tab (courses/show): the Project Details
# card's three states and the student-only My Submission section, per §13.10.
# rack_test cannot resize the viewport or measure scrollWidth, so the
# responsive smoke cases live in the Selenium-driven class at the bottom.
class OverviewTabTest < ApplicationSystemTestCase
  setup do
    @course = create(:course)

    @coordinator_user = create(:user)
    @coordinator_enrolment = create(:enrolment, :coordinator, user: @coordinator_user, course: @course)

    @lecturer_user = create(:user, :staff)
    @lecturer_enrolment = create(:enrolment, :lecturer, user: @lecturer_user, course: @course)

    @student_user = create(:user)
    @student_enrolment = create(:enrolment, user: @student_user, course: @course)
  end

  test 'coordinator with no details sees the add-details CTA linked to settings' do
    login_as @coordinator_user
    visit course_path(@course)

    assert_text 'No project details yet'
    assert_link 'Add details', href: settings_course_path(@course)
  end

  test 'student with no details sees the read-only empty state and no CTA' do
    login_as @student_user
    visit course_path(@course)

    assert_text 'No project details published yet'
    assert_no_link 'Add details'
  end

  test 'lecturer with no details sees the read-only empty state and no CTA' do
    login_as @lecturer_user
    visit course_path(@course)

    assert_text 'No project details published yet'
    assert_no_link 'Add details'
  end

  test 'filled banner renders the description and the illustration' do
    @course.update!(course_description: 'Welcome to the final year group project module.')
    login_as @student_user
    visit course_path(@course)

    assert_text 'Project Details'
    assert_text 'Welcome to the final year group project module.'
    assert_selector 'img[src*="project_details_banner"]'
  end

  test 'filled banner renders and truncates the file pill' do
    @course.update!(file_link: 'http://example.test/Project_Specifications_FINAL.pdf')
    login_as @student_user
    visit course_path(@course)

    assert_text 'Project_Specifications_FINAL.pdf'
    assert_selector 'span.truncate', text: 'Project_Specifications_FINAL.pdf'
    assert_selector 'img[src*="project_details_banner"]'
  end

  test 'coordinator and lecturer never see the My Submission section' do
    login_as @coordinator_user
    visit course_path(@course)
    assert_no_text 'My Submission'

    login_as @lecturer_user
    visit course_path(@course)
    assert_no_text 'My Submission'
  end

  test 'student in a grouped course with grouping enabled and no group gets the browse CTA' do
    @course.update!(grouped: true, grouping_enabled: true, grouping_open: false, group_min: 2, group_max: 5)
    login_as @student_user
    visit course_path(@course)

    assert_text "You're not in a group yet"

    click_link 'Browse groups'
    assert_current_path course_project_groups_path(@course)
  end

  test 'student in a grouped course with grouping disabled and no group gets the create-proposal copy' do
    @course.update!(grouped: true)
    login_as @student_user
    visit course_path(@course)

    assert_text 'No proposal submitted yet'
    assert_no_text 'Browse groups'
    assert_link 'Create proposal', href: new_course_project_path(@course)
  end

  test 'student in a group but with no project gets the create-proposal copy' do
    @course.update!(grouped: true)
    group = create(:project_group, course: @course, confirmed: true)
    create(:project_group_member, user: @student_user, project_group: group)

    login_as @student_user
    visit course_path(@course)

    assert_text 'No proposal submitted yet'
    assert_link 'Create proposal', href: new_course_project_path(@course)
  end

  test 'student with a pending project sees the row with the pending pill' do
    give_student_project(status: :pending, title: 'Pending Proposal')
    login_as @student_user
    visit course_path(@course)

    within('#my-submission') do
      assert_text 'Pending Proposal'
      assert_text 'Pending'
    end
  end

  test 'student with an approved project sees the row with the approved pill' do
    give_student_project(status: :approved, title: 'Approved Proposal')
    login_as @student_user
    visit course_path(@course)

    within('#my-submission') do
      assert_text 'Approved Proposal'
      assert_text 'Approved'
    end
  end

  test 'student with a redo project sees the row plus the redo note' do
    give_student_project(status: :redo, title: 'Redo Proposal')
    login_as @student_user
    visit course_path(@course)

    within('#my-submission') do
      assert_text 'Redo Proposal'
      assert_text 'Redo'
      assert_text 'Your coordinator asked for changes'
    end
  end

  test 'student with a rejected project sees the row with the rejected pill' do
    give_student_project(status: :rejected, title: 'Rejected Proposal')
    login_as @student_user
    visit course_path(@course)

    within('#my-submission') do
      assert_text 'Rejected Proposal'
      assert_text 'Rejected'
    end
  end

  private

  def give_student_project(status:, title:)
    project = create(:project, course: @course, owner: @student_user, owner_type: 'User',
                               supervisor_enrolment: @lecturer_enrolment, status: status)
    create(:project_instance, project: project, supervisor_enrolment: @lecturer_enrolment,
                              created_by: @student_user, status: status, title: title)
  end
end

# Real-browser responsive smoke for the Overview states, following the
# MobileOverflowTest pattern (test/system/projects/mobile_overflow_test.rb):
# rack_test cannot resize the viewport or measure scrollWidth, so this drives
# headless Chrome at 390x844 and asserts the golden rule — no page-level
# horizontal overflow while the banner crop and empty-state stack behave.
class OverviewTabMobileTest < ApplicationSystemTestCase
  self.use_transactional_tests = false

  driven_by :selenium, using: :headless_chrome, screen_size: [390, 844]

  setup do
    @users = []
    @courses = []
    page.driver.browser.manage.window.resize_to(390, 844)
  end

  teardown do
    # Courses first (their projects/enrolments reference the users), then users.
    @courses&.each do |course|
      Course.transaction do
        pids = course.projects.ids
        ProjectInstance.where(project_id: pids).find_each { |i| i.project_instance_fields.delete_all }
        ProjectInstance.where(project_id: pids).delete_all
        Project.where(id: pids).delete_all

        template = course.project_template
        template&.project_template_fields&.delete_all
        template&.delete

        course.enrolments.delete_all
        course.project_groups.delete_all
        course.delete
      end
    end

    @users&.each do |user|
      user.sessions.delete_all
      user.otp&.delete
      user.delete
    end
  end

  def make_user(**attrs)
    user = create(:user, **attrs)
    @users << user
    user
  end

  def make_course(**attrs)
    course = create(:course, **attrs)
    @courses << course
    course
  end

  def login_as(user, password: 'password')
    super
    assert_current_path root_path, wait: Capybara.default_max_wait_time * 2
  end

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

  def assert_no_page_overflow
    json = wait_for_stable_metrics(
      'JSON.stringify([document.documentElement.scrollWidth, document.documentElement.clientWidth])'
    )
    scroll_width, client_width = JSON.parse(json)
    assert_operator scroll_width, :<=, client_width,
                    "page should not scroll sideways at 390px (scrollWidth=#{scroll_width}, clientWidth=#{client_width})"
  end

  test '390px: filled banner and an approved submission row fit with no horizontal overflow' do
    course = make_course(
      course_description: 'Mobile spec for the handbook.',
      file_link: 'http://example.test/Project_Specifications_FINAL.pdf'
    )
    student = make_user
    create(:enrolment, role: :student, user: student, course: course)
    lecturer = make_user(:staff, name: 'Alice Zane')
    lecturer_enr = create(:enrolment, role: :lecturer, user: lecturer, course: course)
    project = create(:project, course: course, owner: student, owner_type: 'User',
                               supervisor_enrolment: lecturer_enr, status: :approved)
    create(:project_instance, project: project, supervisor_enrolment: lecturer_enr,
                              created_by: student, status: :approved, title: 'EduPulse Analytics Platform')

    login_as(student)
    visit course_path(course)

    assert_selector 'img[src*="project_details_banner"]'
    assert_text 'Mobile spec for the handbook.'
    assert_no_page_overflow

    within('#my-submission') do
      assert_text 'EduPulse Analytics Platform'
      assert_text 'Approved'
    end
  end

  test '390px: no-proposal empty state stacks and shows the create CTA with no overflow' do
    course = make_course
    student = make_user
    create(:enrolment, role: :student, user: student, course: course)

    login_as(student)
    visit course_path(course)

    assert_text 'No project details published yet'
    assert_text 'No proposal submitted yet'
    assert_link 'Create proposal', href: new_course_project_path(course)

    direction = page.evaluate_script(<<~JS)
      (function () {
        var el = document.querySelector('#my-submission .flex.items-center.text-center.gap-3');
        return el ? getComputedStyle(el).flexDirection : null;
      })()
    JS
    assert_equal 'column', direction, 'empty state should stack vertically at 390px'

    assert_no_page_overflow
  end
end
