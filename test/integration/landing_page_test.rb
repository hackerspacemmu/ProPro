require 'test_helper'

# The public landing page at root. Signed-out visitors see it, signed-in
# visitors bounce to the dashboard. Both call-to-action buttons log in.
class LandingPageTest < ActionDispatch::IntegrationTest
  test 'root renders the landing page for a logged-out visitor' do
    get root_path

    assert_response :success
    assert_select 'section[data-controller="landing"]', count: 3
  end

  test 'both call-to-action buttons log in' do
    get root_path

    assert_select 'a.btn.big[href="/login"]', text: 'Log in to ProPro', count: 2
  end

  test 'a signed-in user visiting the root is redirected to the dashboard' do
    user = User.create!(email_address: 'landing@example.com', name: 'Landing User', password: 'password', has_registered: true)

    post session_path, params: { email_address: user.email_address, password: 'password' }
    assert_response :redirect

    get root_path
    assert_redirected_to dashboard_path
  end

  test 'dashboard requires authentication' do
    get dashboard_path

    assert_redirected_to login_path
  end
end
