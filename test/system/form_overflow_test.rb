require 'application_system_test_case'

# Real-browser regression guard for the 360px horizontal overflow that the
# project/topic new+edit forms shipped with (the header's Discard + save
# buttons stretched past the viewport edge). rack_test cannot resize the
# viewport or measure scrollWidth, so this file drives headless Chrome at
# 360x760 and asserts the page never scrolls sideways — while the mobile
# layout swaps the header buttons for a fixed bottom action bar instead.
class FormOverflowTest < ApplicationSystemTestCase
  self.use_transactional_tests = false

  driven_by :selenium, using: :headless_chrome, screen_size: [360, 760]

  def login_as(user, password: 'password')
    visit login_path
    fill_in 'email_address', with: user.email_address
    fill_in 'password', with: password
    click_button 'Sign In'
    assert_current_path root_path, wait: Capybara.default_max_wait_time * 2
  end

  def assert_no_overflow(path)
    visit path
    assert_current_path path, wait: 3

    # Linux Chrome reserves a 15px scrollbar and fonts settle after load, so
    # wait for two consecutive reads to agree before asserting geometry.
    deadline = Time.zone.now + 5
    previous = nil
    loop do
      current = page.evaluate_script(
        'JSON.stringify([document.documentElement.scrollWidth, document.documentElement.clientWidth])'
      )
      break if previous == current

      previous = current
      assert_operator Time.zone.now, :<, deadline, 'document metrics never stabilized'
      sleep 0.15
    end
    scroll_width, client_width = JSON.parse(previous)

    assert_operator scroll_width, :<=, client_width,
                    "#{path} scrolls sideways at the current viewport (scrollWidth=#{scroll_width} clientWidth=#{client_width})"

    # Selenium test classes share one process-browser whose effective width is
    # whichever class registered the driver last, so this must hold at any
    # width: the pinned bottom action bar shows below 1245px and never above —
    # the mobile header buttons are hidden while the desktop ones stay.
    width = page.evaluate_script('window.innerWidth')
    display = page.evaluate_script(
      'getComputedStyle(document.querySelector(".fixed.bottom-0")).display'
    )
    if width < 1245
      assert_equal 'flex', display, "#{path}: bottom action bar must be visible at #{width}px"
    else
      assert_equal 'none', display, "#{path}: bottom action bar must stay hidden at #{width}px"
    end
  end

  test 'project new/edit have no horizontal overflow at 360px' do
    course  = create(:course, toggle_topics: true)
    student = create(:user, is_staff: false)
    create(:enrolment, :student, user: student, course: course)
    lecturer = create(:user, is_staff: true, name: 'Alice Zane')
    create(:enrolment, :lecturer, user: lecturer, course: course)
    create(:enrolment, :lecturer, course: course)
    create(:enrolment, :coordinator, course: course)

    login_as(student)
    assert_no_overflow(new_course_project_path(course))

    # The picker <dialog>s must stay hidden while closed. Their mobile layout
    # gives the dialog element author flex display, which overrides the UA's
    # dialog:not([open]) hiding — regression guard so a closed picker can never
    # render visible on the form.
    assert_selector '[data-method-picker-target="topicDialog"]:not([open])', visible: :all
    assert_selector '[data-method-picker-target="lecturerDialog"]:not([open])', visible: :all
    assert_no_selector '[data-method-picker-target="topicDialog"][open]'

    project = create(:project, course: course, owner: student)
    create(:project_instance, project: project, created_by: student,
                              version: 1, status: :pending, title: 'My Proposal')
    assert_no_overflow(edit_course_project_path(course, project))

    Course.transaction do
      course.projects.each do |p|
        p.project_instances.each do |i|
          i.comments.delete_all
          i.project_instance_fields.delete_all
        end
      end
      ProjectInstance.where(project_id: course.projects.ids).delete_all
      course.projects.delete_all
      course.project_template&.project_template_fields&.delete_all
      course.project_template&.delete
      course.enrolments.delete_all
      [student, lecturer].each do |u|
        u.sessions.delete_all
        u.otp&.delete
        u.comments.delete_all
      end
      course.delete
      [student, lecturer].each(&:delete)
    end
  end

  test 'topic new/edit have no horizontal overflow at 360px' do
    course = create(:course, toggle_topics: true)
    lecturer = create(:user, is_staff: true, name: 'Alice Zane')
    create(:enrolment, :lecturer, user: lecturer, course: course)

    login_as(lecturer)
    assert_no_overflow(new_course_topic_path(course))

    topic = create(:topic, course: course, owner: lecturer)
    create(:topic_instance, topic: topic, created_by: lecturer, version: 1,
                            status: :pending, title: 'My Topic')
    assert_no_overflow(edit_course_topic_path(course, topic))

    Course.transaction do
      course.topics.each do |t|
        t.topic_instances.each do |i|
          i.comments.delete_all
          i.project_instance_fields.delete_all
        end
      end
      TopicInstance.where(project_id: course.topics.ids).delete_all
      course.topics.delete_all
      course.project_template&.project_template_fields&.delete_all
      course.project_template&.delete
      course.enrolments.delete_all
      lecturer.sessions.delete_all
      lecturer.otp&.delete
      course.delete
      lecturer.delete
    end
  end
end
