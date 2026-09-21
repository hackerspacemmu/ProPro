require 'test_helper'

class UserControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, name: 'Final Test User')
  end

  test 'profile renders the course-settings-style edit profile chrome' do
    sign_in @user
    get user_profile_path
    assert_response :success
    assert_select 'header' do
      assert_select 'h1', text: 'Edit Profile'
      assert_select 'input[type=submit][value="Save"]'
    end
    assert_select 'h2', text: 'Account Details'
    assert_select 'h2', text: 'Change Password'
    assert_select 'form#edit-profile-form'
    assert_select 'a', text: 'Discard Changes'
    assert_no_match 'Back to Dashboard', response.body
  end

  test 'edit updates the profile and redirects' do
    sign_in @user
    post user_edit_path, params: { user: { name: 'Updated Name', web_link: 'https://example.com', description: 'Hello' } }
    assert_redirected_to user_profile_path
    assert_equal 'Updated Name', @user.reload.name
    assert_equal 'https://example.com', @user.web_link
    assert_equal 'Hello', @user.description
  end

  private

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
