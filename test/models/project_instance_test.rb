require 'test_helper'

class ProjectInstanceTest < ActiveSupport::TestCase
  setup do
    @course    = FactoryBot.create(:course)
    @user      = FactoryBot.create(:user, is_staff: false)
    @enrolment = FactoryBot.create(:enrolment, user: @user, course: @course, role: :student)
    @project   = FactoryBot.create(:project, course: @course, owner: @user, enrolment: @enrolment)
  end

  test "ProjectInstance created with happy paths" do
    instance = ProjectInstance.create!(
      project: @project,
      enrolment: @enrolment,
      created_by: @user,
      version: 1,
      title: "Test Project Title"
    )

    assert_equal "pending", instance.status
    assert_equal "project", instance.project_instance_type
    assert_equal 1, instance.version
  end

  test "Parent Project status is updated to match latest ProjectInstance status after save" do
    ProjectInstance.create!(
      project: @project,
      enrolment: @enrolment,
      created_by: @user,
      version: 1,
      title: "Test Project Title"
    )

    assert_equal "pending", @project.reload.status
  end

  test "current_instance returns the instance with the highest version" do
    instance_v1 = ProjectInstance.create!(
      project: @project, enrolment: @enrolment,
      created_by: @user, version: 1,
      title: "Test Project Title"
    )
    instance_v2 = ProjectInstance.create!(
      project: @project, enrolment: @enrolment,
      created_by: @user, version: 2,
      title: "Test Project Title"
    )

    assert_equal instance_v2, @project.current_instance
  end

  test "current_instance returns nil when no instances exist" do
    assert_nil @project.current_instance
  end
end