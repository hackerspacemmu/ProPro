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

  test 'student in a grouped course with grouping open and no group gets find-or-create CTA' do
    @course.update!(grouped: true, group_formation_enabled: true, group_min: 2, group_max: 5)
    login_as @student_user
    visit course_path(@course)

    assert_text "You're not in a group yet"

    click_link 'Find or create a group'
    assert_current_path course_group_formation_path(@course)
  end

  test 'student in a grouped course with grouping closed and no group gets closed copy' do
    @course.update!(grouped: true, group_formation_enabled: true, group_formation_closes_at: 1.hour.ago, group_min: 2, group_max: 5)
    login_as @student_user
    visit course_path(@course)

    assert_text 'Group formation is closed'
    assert_text 'Contact your coordinator if you are not in a group yet.'
    assert_no_link 'Find or create a group'
    assert_no_link 'Create proposal'
  end

  test 'student in a grouped course with grouping disabled and no group gets closed copy' do
    @course.update!(grouped: true, group_formation_enabled: false)
    login_as @student_user
    visit course_path(@course)

    assert_text 'Group formation is closed'
    assert_text 'Contact your coordinator if you are not in a group yet.'
    assert_no_link 'Find or create a group'
    assert_no_link 'Create proposal'
  end

  test 'student in a non-grouped course gets create-proposal copy' do
    @course.update!(grouped: false)
    login_as @student_user
    visit course_path(@course)

    assert_text 'No proposal submitted yet'
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

  test 'student in unconfirmed group sees My Group card and no My Submission' do
    @course.update!(grouped: true, group_formation_enabled: true, group_min: 2, group_max: 4)
    group = create(:project_group, course: @course, confirmed: false, group_name: 'Tmp001', leader_id: @student_user.id)
    create(:project_group_member, user: @student_user, project_group: group)

    login_as @student_user
    visit course_path(@course)

    assert_selector '#my-group[data-testid="my-group-panel"], #my-group section[data-testid="my-group-panel"]'
    assert_text 'Tmp001'
    assert_text 'Not confirmed'
    assert_text 'Leader'
    assert_text '1 of 4'
    assert_link 'Review and confirm', href: course_group_formation_path(@course)
    assert_no_selector '#my-submission'
  end

  test 'student My Group members count shows no maximum when none is set' do
    @course.update!(grouped: true, group_formation_enabled: true, group_min: 2, group_max: nil)
    group = create(:project_group, course: @course, confirmed: false, group_name: 'Tmp001', leader_id: @student_user.id)
    create(:project_group_member, user: @student_user, project_group: group)

    login_as @student_user
    visit course_path(@course)

    within('#my-group') do
      assert_text 'MEMBERS'
      assert_no_text '1 of'
    end
  end

  test 'student in confirmed group sees My Group line and My Submission' do
    @course.update!(grouped: true, group_formation_enabled: true, group_min: 2, group_max: 4)
    group = create(:project_group, course: @course, confirmed: true, group_name: 'G001')
    create(:project_group_member, user: @student_user, project_group: group)

    login_as @student_user
    visit course_path(@course)

    assert_selector '#my-group[data-testid="my-group-line"]'
    assert_text 'G001'
    assert_link 'View group', href: course_group_formation_path(@course)
    assert_selector '#my-submission'
    assert_text 'No proposal submitted yet'
  end

  test 'coordinator sees Group formation block with settings link and status' do
    @course.update!(grouped: true, group_formation_enabled: true)
    create(:project_group, course: @course, confirmed: true, group_name: 'G001')

    login_as @coordinator_user
    visit course_path(@course)

    within('#group-formation') do
      assert_text 'Group formation'
      assert_text 'Open'
      assert_link 'Settings', href: settings_course_path(@course, anchor: 'grouping')
      assert_link 'Open group formation', href: course_group_formation_path(@course)
    end
  end

  test 'coordinator sees closed attention banner when formation closed with unconfirmed groups' do
    @course.update!(grouped: true, group_formation_enabled: true, group_formation_closes_at: 1.hour.ago)
    create(:project_group, course: @course, confirmed: false, group_name: 'Tmp001')

    login_as @coordinator_user
    visit course_path(@course)

    within('#group-formation') do
      assert_text 'Group formation'
      assert_text 'Closed'
      assert_text 'Group formation is closed.'
      assert_text '1 group is not confirmed, so their members cannot submit a proposal.'
      assert_link 'Review groups', href: course_groups_path(@course, status_filter: 'not_confirmed')
    end
  end

  test 'lecturer sees Group formation block without settings link or banner' do
    @course.update!(grouped: true, group_formation_enabled: true)

    login_as @lecturer_user
    visit course_path(@course)

    within('#group-formation') do
      assert_text 'Group formation'
      assert_text 'Open'
      assert_no_link 'Settings'
      assert_text 'Students are forming groups.'
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
class OverviewTabMobileTest < BrowserSystemTestCase
  self.viewport_size = [390, 844]

  setup do
    @users = []
    @courses = []
  end

  def make_user(*traits, **attrs)
    user = create(:user, *traits, **attrs)
    @users << user
    user
  end

  def make_course(**attrs)
    course = create(:course, **attrs)
    @courses << course
    course
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
