require 'test_helper'

class ProjectInstanceTest < ActiveSupport::TestCase
  setup do
    @course    = FactoryBot.create(:course)
    @user      = FactoryBot.create(:user, is_staff: false)
    @enrolment = FactoryBot.create(:enrolment, user: @user, course: @course, role: :student)
    @project   = FactoryBot.create(:project, course: @course, owner: @user, enrolment: @enrolment)
  end

  test "project instance created with happy paths" do
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

  test "saving project instance updates the parent project status happy path" do
    ProjectInstance.create!(
      project: @project,
      enrolment: @enrolment,
      created_by: @user,
      version: 1,
      title: "Test Project Title"
    )

    assert_equal "pending", @project.reload.status
  end

  test "saving an older instance does not overwrite parent project status sad path" do
    instance_v1 = ProjectInstance.create!(
      project: @project, enrolment: @enrolment,
      created_by: @user, version: 1,
      title: "Test Project Title", status: :pending
    )
    instance_v2 = ProjectInstance.create!(
      project: @project, enrolment: @enrolment,
      created_by: @user, version: 2,
      title: "Test Project Title 2", status: :approved
    )

    instance_v1.update!(title: "Updated Title")

    assert_equal "approved", @project.reload.status
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
      title: "Test Project Title 2"
    )

    assert_equal instance_v2, @project.current_instance
  end

  test "current_instance returns nil when no instances exist" do
    assert_nil @project.current_instance
  end

  test "approved project is not editable" do
    @project.update_column(:status, :approved)
    assert_not @project.editable?
  end

  test "pending project is editable" do
    @project.update_column(:status, :pending)
    assert @project.editable?
  end

  test "cannot create two instances with the same version for the same project" do
    ProjectInstance.create!(
      project: @project, enrolment: @enrolment,
      created_by: @user, version: 1, title: "First"
    )

    assert_raises ActiveRecord::RecordNotUnique do
      ProjectInstance.create!(
        project: @project, enrolment: @enrolment,
        created_by: @user, version: 1, title: "Duplicate"
      )
    end
  end
end