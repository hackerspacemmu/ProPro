require 'application_system_test_case'

# Real-browser regression guard for the 360px horizontal overflow that the
# project/topic new+edit forms shipped with (the header's Discard + save
# buttons stretched past the viewport edge). rack_test cannot resize the
# viewport or measure scrollWidth, so this drives headless Chrome at 360x760
# and asserts the page never scrolls sideways — while the mobile layout swaps
# the header buttons for a fixed bottom action bar instead.
class FormOverflowTest < BrowserSystemTestCase
  self.viewport_size = [360, 760]

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

    # This class always runs at a sub-1245px viewport, so the pinned bottom
    # action bar must be showing: the mobile header buttons are hidden while
    # the desktop ones stay.
    width = page.evaluate_script('window.innerWidth')
    display = page.evaluate_script(
      'getComputedStyle(document.querySelector(".fixed.bottom-0")).display'
    )
    assert_equal 'flex', display, "#{path}: bottom action bar must be visible at #{width}px"
  end

  test 'project new/edit have no horizontal overflow at 360px' do
    course  = create(:course, toggle_topics: true)
    student = create(:user)
    create(:enrolment, :student, user: student, course: course)
    lecturer = create(:user, :staff, name: 'Alice Zane')
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
  end

  test 'topic new/edit have no horizontal overflow at 360px' do
    course = create(:course, toggle_topics: true)
    lecturer = create(:user, :staff, name: 'Alice Zane')
    create(:enrolment, :lecturer, user: lecturer, course: course)

    login_as(lecturer)
    assert_no_overflow(new_course_topic_path(course))

    topic = create(:topic, course: course, owner: lecturer)
    create(:topic_instance, topic: topic, created_by: lecturer, version: 1,
                            status: :pending, title: 'My Topic')
    assert_no_overflow(edit_course_topic_path(course, topic))
  end
end
