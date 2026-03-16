require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  setup do
    @course           = create(:course)
    @student          = create(:user, is_staff: false)
    @lecturer         = create(:user, is_staff: true)
    @student_enrolment  = create(:enrolment, :student, user: @student, course: @course)
    @lecturer_enrolment = create(:enrolment, :lecturer, user: @lecturer, course: @course)
    @project          = create(:project, course: @course, owner: @student, enrolment: @lecturer_enrolment)
    @instance         = create(:project_instance, project: @project, enrolment: @lecturer_enrolment, created_by: @student, version: 1)
  end

  test "instance_to_edit returns new instance when project is rejected" do
    @project.update_column(:status, :rejected)

    result = @project.instance_to_edit(created_by: @student, has_supervisor_comment: false)

    assert result.new_record?
    assert_equal 2, result.version
  end

  test "instance_to_edit returns new instance when project is redo" do
    @project.update_column(:status, :redo)

    result = @project.instance_to_edit(created_by: @student, has_supervisor_comment: false)

    assert result.new_record?
    assert_equal 2, result.version
  end

  test "instance_to_edit returns new instance when pending with supervisor comment" do
    @project.update_column(:status, :pending)

    result = @project.instance_to_edit(created_by: @student, has_supervisor_comment: true)

    assert result.new_record?
    assert_equal 2, result.version
  end

  test "instance_to_edit returns existing instance when pending with no supervisor comment" do
    @project.update_column(:status, :pending)

    result = @project.instance_to_edit(created_by: @student, has_supervisor_comment: false)

    assert_not result.new_record?
    assert_equal @instance, result
  end
end