require 'application_system_test_case'

# Version navigation for the topics show page is driven client-side: the
# version `<select>` is wired to version_select_controller.js, which navigates
# to the current path with a new `?version=`. rack_test never executes
# JavaScript, so this class drives headless Chrome to exercise the real
# select -> navigate behaviour.
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

    first('select[data-controller="version-select"]').select('2 of 2 (Latest)')

    assert_current_path course_topic_path(@course, @topic, version: 2), wait: Capybara.default_max_wait_time
  end

  test 'chevron arrows flank the version select' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    assert_selector 'a[aria-label="Previous version"]'
    assert_selector 'button[aria-label="Next version"][disabled]'
  end

  test 'previous chevron is disabled on version 1' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic, version: 1)

    assert_selector 'button[aria-label="Previous version"][disabled]'
    assert_selector 'a[aria-label="Next version"]'
  end
end
