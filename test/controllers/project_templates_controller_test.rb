require 'test_helper'

class ProjectTemplatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @title_field = @course.project_template.project_template_fields.find_by(is_project_title: true)
    sign_in @coordinator
  end

  test 'title row keeps a submittable field_type despite its disabled Type select' do
    get edit_course_project_template_path(@course)

    assert_response :success
    assert_select "select[name$='[field_type]'][disabled]"
    assert_select "input[type=hidden][name$='[field_type]']", value: @title_field.field_type
  end

  test 'coordinator can edit the title field description and applicable_to' do
    patch course_project_template_path(@course), params: {
      project_template: {
        project_template_fields_attributes: {
          '0' => {
            id: @title_field.id,
            label: @title_field.label,
            hint: 'New description',
            field_type: @title_field.field_type,
            applicable_to: 'proposals',
            required: '1',
            free_edit: '0',
            position: '1',
            _destroy: '0'
          }
        }
      }
    }

    assert_redirected_to edit_course_project_template_path(@course)

    @title_field.reload
    assert_equal 'New description', @title_field.hint
    assert_equal 'proposals', @title_field.applicable_to
    assert_equal 'shorttext', @title_field.field_type
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
