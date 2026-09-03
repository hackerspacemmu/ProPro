require 'application_system_test_case'

# Version navigation for the topics show page is driven client-side: the
# version `<select>` is wired to version_select_controller.js, which fires
# `window.location.href = /courses/:course/topics/:topic?version=N`. rack_test
# never executes JavaScript, so this class drives headless Chrome (like
# test/system/projects/mobile_overflow_test.rb) to exercise the real
# select → navigate behaviour.
#
# Uses `use_transactional_tests = false`: with a real browser the app runs on a
# server thread whose DB connection cannot see rows uncommitted in the test's
# transaction, so FactoryBot records must be committed for the login to work.
class TopicVersioningTest < ApplicationSystemTestCase
  self.use_transactional_tests = false

  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  setup do
    @course   = create(:course)
    @lecturer = create(:user, is_staff: true)

    create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @topic      = create(:topic, course: @course, owner: @lecturer)
    @instance_1 = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 1, status: :pending)
    @instance_2 = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 2, status: :pending)
  end

  teardown do
    return if @course.nil?

    # With use_transactional_tests = false nothing rolls back; delete records
    # directly in FK order instead of relying on dependent callbacks.
    Course.transaction do
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

      [@lecturer].compact.each do |user|
        user.sessions.delete_all
        user.otp&.delete
      end

      @course.delete
      @lecturer.delete
    end
  end

  # Turbo submits the login form via fetch; wait deterministically for the
  # post-login redirect so navigation assertions below don't race it.
  def login_as(user, password: 'password')
    super
    assert_current_path root_path, wait: Capybara.default_max_wait_time * 2
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
