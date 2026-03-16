require 'test_helper'

class TopicTest < ActiveSupport::TestCase
  setup do
    @course   = create(:course)
    @lecturer = create(:user, is_staff: true)
    create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @topic    = create(:topic, course: @course, owner: @lecturer)
    @instance = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 1, status: :pending)
  end

  test 'instance_to_edit returns new instance when topic is rejected' do
    @topic.update_column(:status, :rejected)

    result = @topic.instance_to_edit(created_by: @lecturer, has_coordinator_comment: false, status: :pending)

    assert result.new_record?
    assert_equal 2, result.version
  end

  test 'instance_to_edit returns new instance when topic is redo' do
    @topic.update_column(:status, :redo)

    result = @topic.instance_to_edit(created_by: @lecturer, has_coordinator_comment: false, status: :pending)

    assert result.new_record?
    assert_equal 2, result.version
  end

  test 'instance_to_edit returns new instance when pending with coordinator comment' do
    @topic.update_column(:status, :pending)

    result = @topic.instance_to_edit(created_by: @lecturer, has_coordinator_comment: true, status: :pending)

    assert result.new_record?
    assert_equal 2, result.version
  end

  test 'instance_to_edit returns existing instance when pending with no coordinator comment' do
    @topic.update_column(:status, :pending)

    result = @topic.instance_to_edit(created_by: @lecturer, has_coordinator_comment: false, status: :pending)

    assert_not result.new_record?
    assert_equal @instance, result
  end

  test 'topic ownership_type is always lecturer' do
    assert_equal 'lecturer', @topic.ownership_type
  end
end
