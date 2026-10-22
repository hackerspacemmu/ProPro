require 'test_helper'

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course   = create(:course)
    @student  = create(:user)
    create(:enrolment, :student, user: @student, course: @course)

    @lecturer     = create(:user, :staff, name: 'Alice Zane')
    @lecturer_enr = create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @other_lecturer     = create(:user, :staff, name: 'Bob Ray')
    @other_lecturer_enr = create(:enrolment, :lecturer, user: @other_lecturer, course: @course)

    @title_field = @course.project_template.project_template_fields.first
  end

  test 'an approved project keeps its supervisor when another one is requested' do
    # The owner may edit an approved project only when the template has a
    # free-edit field; this one gets the request past ProjectPolicy#update?
    # so it reaches the supervisor guard.
    create(:project_template_field, project_template: @course.project_template,
                                    label: 'Progress Notes', field_type: :textarea,
                                    applicable_to: :both, free_edit: true)
    project = build_project

    sign_in @student
    patch course_project_path(@course, project), params: {
      based_on_topic: "own_proposal_#{@other_lecturer_enr.id}",
      fields: { @title_field.id.to_s => 'Original Title' }
    }

    assert_redirected_to course_project_path(@course, project)
    assert flash[:alert].present?
    assert_equal @lecturer_enr, project.reload.supervisor_enrolment
    assert_equal @lecturer, project.supervisor
  end

  private

  def build_project
    project = create(:project, course: @course, owner: @student,
                               supervisor_enrolment: @lecturer_enr, status: :approved)
    instance = create(:project_instance, project: project, supervisor_enrolment: @lecturer_enr,
                                         created_by: @student, version: 1, status: :approved,
                                         title: 'Original Title')
    instance.project_instance_fields.create!(project_template_field_id: @title_field.id,
                                             value: 'Original Title')
    project
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
