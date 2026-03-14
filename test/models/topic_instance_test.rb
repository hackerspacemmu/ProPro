require 'test_helper'
class TopicInstanceTest < ActiveSupport::TestCase
  setup do
    @course  = FactoryBot.create(:course)
    @user    = FactoryBot.create(:user, is_staff: true)
    @topic   = FactoryBot.create(:topic, course: @course, owner: @user)
  end

  test "topic instance created with correct defaults" do
    instance = TopicInstance.create!(
      topic: @topic,
      created_by: @user,
      version: 1,
      title: "Test Topic Title"
    )
    assert_equal "pending", instance.status
    assert_equal "topic", instance.project_instance_type
    assert_equal 1, instance.version
  end

  test "saving topic instance updates parent topic status" do
    TopicInstance.create!(
      topic: @topic, created_by: @user,
      version: 1, title: "Test Topic Title"
    )
    assert_equal "pending", @topic.reload.status
  end

  test "saving an older instance does not overwrite parent topic status" do
    TopicInstance.create!(
      topic: @topic, created_by: @user,
      version: 1, title: "v1", status: :pending
    )
    instance_v2 = TopicInstance.create!(
      topic: @topic, created_by: @user,
      version: 2, title: "v2", status: :approved
    )
    TopicInstance.find_by(version: 1, project_id: @topic.id)
                 .update_column(:title, "Updated")
    assert_equal "approved", @topic.reload.status
  end

  test "current_instance returns the instance with the highest version" do
    TopicInstance.create!(topic: @topic, created_by: @user, version: 1, title: "v1")
    v2 = TopicInstance.create!(topic: @topic, created_by: @user, version: 2, title: "v2")
    assert_equal v2, @topic.current_instance
  end

  test "current_instance returns nil when no instances exist" do
    assert_nil @topic.current_instance
  end

  test "topic ownership_type is always lecturer" do
    assert_equal "lecturer", @topic.ownership_type
  end

  test "cannot create two topic instances with the same version" do
    TopicInstance.create!(topic: @topic, created_by: @user, version: 1, title: "First")
    assert_raises ActiveRecord::RecordNotUnique do
      TopicInstance.create!(topic: @topic, created_by: @user, version: 1, title: "Duplicate")
    end
  end
end