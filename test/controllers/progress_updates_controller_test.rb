require 'test_helper'

class ProgressUpdatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course, use_progress_updates: true, number_of_updates: 10)
    @lecturer = create(:user)
    @lecturer_enrolment = create(:enrolment, :lecturer, user: @lecturer, course: @course)
    @student = create(:user)
    create(:enrolment, user: @student, course: @course)

    @project = create(:project, course: @course, supervisor_enrolment: @lecturer_enrolment, owner: @student)
    create(:project_instance, project: @project, supervisor_enrolment: @lecturer_enrolment, created_by: @student)
  end

  test 'create redirects to the progress updates tab' do
    sign_in @lecturer

    assert_difference -> { ProgressUpdate.count }, 1 do
      post course_project_progress_updates_path(@course, @project),
           params: { progress_update: { rating: 'satisfactory', feedback: 'Good work', date: Date.current } }
    end

    assert_redirected_to course_project_progress_updates_path(@course, @project)
  end

  test 'index 404s when progress updates are disabled' do
    @course.update!(use_progress_updates: false)

    sign_in @lecturer
    get course_project_progress_updates_path(@course, @project)

    assert_response :not_found
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
