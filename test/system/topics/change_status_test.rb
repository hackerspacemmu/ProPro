require 'application_system_test_case'

class TopicChangeStatusTest < ApplicationSystemTestCase
  setup do
    @course      = create(:course, require_coordinator_approval: true)
    @lecturer    = create(:user, is_staff: true)
    @coordinator = create(:user, is_staff: true)

    create(:enrolment, :lecturer, user: @lecturer, course: @course)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)

    @topic    = create(:topic, course: @course, owner: @lecturer)
    @instance = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 1, status: :pending)
  end

  test 'coordinator can change topic status when coordinator approval is required happy path' do
    login_as(@coordinator)
    visit course_topic_path(@course, @topic)

    first('[data-testid="approve-button"]').click

    assert_selector '[data-testid="flash-notice"]'
    assert_selector '[data-testid="review-actions"]'
  end

  test 'if coordinator approval enabled, lecturer cannot change their own topic status sad path' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    assert_no_selector '[data-testid="review-actions"]'
    assert_no_selector '[data-testid="approve-button"]'
  end

  test 'coordinator cannot change status when coordinator approval is not required sad path' do
    @course.update!(require_coordinator_approval: false)
    login_as(@coordinator)
    visit course_topic_path(@course, @topic)

    assert_no_selector '[data-testid="review-actions"]'
    assert_no_selector '[data-testid="approve-button"]'
  end
end
