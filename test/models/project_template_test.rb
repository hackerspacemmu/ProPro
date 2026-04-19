require 'test_helper'

class ProjectTemplateFieldTest < ActiveSupport::TestCase
  setup do
    @course = create(:course)
    @template = @course.project_template
    @title_field = @template.project_template_fields.find_by(is_project_title: true)
  end

  test 'project template always has a title field after creation' do
    assert_not_nil @title_field
    assert @title_field.is_project_title?
  end

  test 'title field cannot be destroyed' do
    assert_not @title_field.destroy
    assert ProjectTemplateField.exists?(@title_field.id)
  end

  test 'title field remains required after being renamed' do
    @title_field.update!(label: 'Study Name')
    assert @title_field.reload.required?
  end

  test 'regular field can be destroyed if not in use' do
    field = create(:project_template_field, project_template: @template)
    assert field.destroy
    assert_not ProjectTemplateField.exists?(field.id)
  end

  test 'is_project_title is false by default for new fields' do
    field = create(:project_template_field, project_template: @template)
    assert_not field.is_project_title?
  end
end
