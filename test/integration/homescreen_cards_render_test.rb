require 'test_helper'

class HomescreenCardsRenderTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @course = create(:course)
    @course.enrolments.create!(user: @user, role: :student)
  end

  test 'homescreen renders themed course cards via image_tag' do
    post session_path, params: { email_address: @user.email_address, password: 'password' }
    assert_redirected_to root_path

    get root_path
    assert_response :success

    assert_select 'div[style*="background:#37474F"]', count: 1
    assert_match(%r{illustrations/scene_8[^"]*\.svg}, @response.body)
  end

  test 'cycling: three courses get three different theme colors' do
    2.times do |_i|
      c = create(:course)
      c.enrolments.create!(user: @user, role: :student)
    end

    post session_path, params: { email_address: @user.email_address, password: 'password' }
    get root_path

    ['#37474F', '#1A73E8', '#5F6368'].each do |color|
      assert_match(Regexp.new("background:#{color}"), @response.body)
    end
    %w[scene_8 scene_5 scene_6].each do |scene|
      assert_match(%r{illustrations/#{scene}[^"]*\.svg}, @response.body)
    end
  end

  test 'homescreen shows Courses panel with mockup join form' do
    post session_path, params: { email_address: @user.email_address, password: 'password' }
    get root_path
    assert_response :success

    assert_select 'h2', text: 'Courses'
    assert_select 'label', text: 'Join a course'
  end

  test 'Add course button is hidden for non-staff students' do
    post session_path, params: { email_address: @user.email_address, password: 'password' }
    get root_path
    assert_response :success

    assert_no_match(/Add class/, @response.body)
    assert_no_match(/Add course/, @response.body)
  end

  test 'Add course button shows for staff' do
    staff = create(:user, :staff)
    @course.enrolments.create!(user: staff, role: :coordinator)

    post session_path, params: { email_address: staff.email_address, password: 'password' }
    get root_path
    assert_response :success

    assert_match(/Add course/, @response.body)
    assert_match(%r{href="/courses/new"}, @response.body)
  end

  test 'shared sidebar and header render on the dashboard' do
    post session_path, params: { email_address: @user.email_address, password: 'password' }
    get root_path
    assert_response :success

    assert_select '#app-sidebar'
    assert_select 'header'
    assert_select 'button[aria-label="Toggle sidebar"]'

    assert_match(/aria-label="Home"/, @response.body)
    assert_match(/Enrolled/, @response.body)
    assert_match(/aria-label="#{Regexp.escape(@course.course_name)}"/, @response.body)
  end
end
