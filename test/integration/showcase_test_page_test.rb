require 'test_helper'

# Temporary coverage for the landing-page spike (root is public): rows render
# with the real screenshots from app/assets/images/landing/ wired in, and the
# dashboard lives at /dashboard. Delete with the spike.
class LandingSpikeTest < ActionDispatch::IntegrationTest
  test 'root renders the landing spike for a logged-out visitor' do
    get root_path

    assert_response :success
    assert_select 'section.feat', count: 3
    assert_select 'button.item', count: 9
    assert_match %r{landing/Project_templates[^"]*\.png}, @response.body
    assert_match %r{landing/Topics[^"]*\.png}, @response.body
    assert_match %r{landing/Projects_show[^"]*\.png}, @response.body
  end

  test 'dashboard requires authentication' do
    get dashboard_path

    assert_redirected_to login_path
  end
end