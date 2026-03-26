require 'application_system_test_case'

class TopicVersioningTest < ApplicationSystemTestCase
  setup do
    @course   = create(:course)
    @lecturer = create(:user, is_staff: true)

    create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @topic      = create(:topic, course: @course, owner: @lecturer)
    @instance_1 = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 1, status: :pending)
    @instance_2 = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 2, status: :pending)
  end

  test 'defaults to latest version on page load' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    assert_selector '[data-testid="current-version"]', text: /2 of 2/i
  end

  test 'clicking back navigates to previous version' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    find('[data-testid="version-back"]').click

    assert_selector '[data-testid="current-version"]', text: /1 of 2/i
  end

  test 'clicking next navigates to next version' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic, version: 1)

    find('[data-testid="version-next"]').click

    assert_selector '[data-testid="current-version"]', text: /2 of 2/i
  end

  test 'back button is disabled on version 1' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic, version: 1)

    assert_no_selector '[data-testid="version-back"]'
  end

  test 'next button is disabled on latest version' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    assert_no_selector '[data-testid="version-next"]'
  end
end
