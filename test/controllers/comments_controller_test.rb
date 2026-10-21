require 'test_helper'

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course)
    @student = create(:user)
    create(:enrolment, user: @student, course: @course)
    @project = create(:project, course: @course, owner: @student)
    @instance = create(:project_instance, project: @project, created_by: @student, version: 1)
  end

  test 'create redirects back to the tab it was posted from' do
    sign_in @student

    assert_difference -> { Comment.count }, 1 do
      post comments_path,
           params: { comment: { source_type: 'ProjectInstance', source_id: @instance.id, user_comment: 'Nice' } },
           headers: { 'HTTP_REFERER' => course_project_version_comparison_path(@course, @project) }
    end

    assert_redirected_to course_project_version_comparison_path(@course, @project)
  end

  test 'create falls back to the canonical project path without a referer' do
    sign_in @student

    post comments_path,
         params: { comment: { source_type: 'ProjectInstance', source_id: @instance.id, user_comment: 'Nice' } }

    assert_redirected_to course_project_path(@course, @project, version: @instance.version)
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
