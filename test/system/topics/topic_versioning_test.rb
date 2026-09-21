require 'application_system_test_case'

# Version navigation for the topics show page is driven client-side: the
# version `<select>` is wired to version_select_controller.js, which fires
# `window.location.href = /courses/:course/topics/:topic?version=N`. rack_test
# never executes JavaScript, so this class drives headless Chrome to exercise
# the real select -> navigate behaviour.
class TopicVersioningTest < BrowserSystemTestCase
  setup do
    @course   = create(:course)
    @lecturer = create(:user, :staff)

    create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @topic = create(:topic, course: @course, owner: @lecturer)
    @first_instance = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 1, status: :pending)
    @second_instance = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 2, status: :pending)
  end

  test 'defaults to latest version on page load' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    assert_selector 'select[data-controller="version-select"] option[value="2"][selected]'
  end

  test 'selecting a version navigates to that version' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    first('select[data-controller="version-select"]').select('1 of 2')

    assert_current_path course_topic_path(@course, @topic, version: 1), wait: Capybara.default_max_wait_time
  end

  test 'started on an older version, selecting re-lands on it correctly' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic, version: 1)

    # On version 1 the server renders the dropdown with 1 of 2 selected.
    assert_selector 'select[data-controller="version-select"] option[value="1"][selected]'

    first('select[data-controller="version-select"]').select('2 of 2 (Current)')

    assert_current_path course_topic_path(@course, @topic, version: 2), wait: Capybara.default_max_wait_time
  end

  # NOTE: The old arrow-based version card had dedicated "back disabled on
  # version 1" and "next disabled on latest version" tests. A `<select>` has no
  # disabled direction — it simply lists every version and highlights the
  # current one. Those two tests have no clean dropdown equivalent and are
  # intentionally not carried forward; the bounded option list itself prevents
  # out-of-range navigation.
end
