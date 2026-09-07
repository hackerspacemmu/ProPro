require 'test_helper'

class TopicsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course      = create(:course, require_coordinator_approval: true)
    @lecturer    = create(:user, :staff)
    @coordinator = create(:user, :staff)

    create(:enrolment, :lecturer, user: @lecturer, course: @course)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    create(:enrolment, :student, user: create(:user), course: @course)

    @topic    = create(:topic, course: @course, owner: @lecturer)
    @instance = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 1, status: :pending)
  end

  test 'lecturer cannot update topic status' do
    sign_in @lecturer
    patch change_status_course_topic_path(@course, @topic), params: { status: 'approved' }

    assert_redirected_to root_path
    assert_equal 'You are not authorized to view this page.', flash[:alert]
    assert_equal 'pending', @topic.current_instance.reload.status
  end

  test 'coordinator can update topic status' do
    sign_in @coordinator
    patch change_status_course_topic_path(@course, @topic), params: { status: 'approved' }

    assert_redirected_to course_topic_path(@course, @topic)
    assert_equal 'Status updated.', flash[:notice]
    assert_equal 'approved', @topic.current_instance.reload.status
  end

  test 'compare tab diffs the latest version against the previous one' do
    field = create(:project_template_field, project_template: @course.project_template, field_type: :textarea)
    @instance.project_instance_fields.create!(project_template_field_id: field.id, value: 'First draft')
    second = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 2, status: :pending)
    second.project_instance_fields.create!(project_template_field_id: field.id, value: 'Polished draft')

    sign_in @coordinator
    get course_topic_path(@course, @topic)

    assert_response :success
    assert_match 'Version 1', response.body
    assert_match 'Version 2 (Current)', response.body
    assert_no_match 'Only one version exists', response.body
  end

  test 'compare tab keeps the empty state for a single-version topic' do
    sign_in @coordinator
    get course_topic_path(@course, @topic)

    assert_response :success
    assert_match 'Only one version exists', response.body
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
