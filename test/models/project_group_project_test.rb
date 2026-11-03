require 'test_helper'

class ProjectGroupProjectTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, :grouped)
    @supervisor = create(:enrolment, :lecturer, course: @course)
    @group = create(:project_group, course: @course, confirmed: true)
  end

  def build_project(owner)
    Project.new(course: @course, owner: owner, supervisor_enrolment: @supervisor)
  end

  test 'a project cannot be created for a not confirmed group' do
    @group.update!(confirmed: false)

    assert_not build_project(@group).valid?
  end

  test 'editing a project still works after the group status changes' do
    project = build_project(@group).tap(&:save!)
    @group.update!(confirmed: false)

    assert project.reload.update(status: :approved), project.errors.full_messages.to_sentence
  end

  test 'the database refuses a second project for the same group' do
    build_project(@group).save!

    assert_raises(ActiveRecord::RecordNotUnique) do
      build_project(@group).save!(validate: false)
    end
  end

  test 'one user can still own several projects' do
    user = create(:user)
    build_project(user).save!

    assert_nothing_raised { build_project(user).save! }
  end
end
