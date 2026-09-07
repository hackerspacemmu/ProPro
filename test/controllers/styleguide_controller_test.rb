require 'test_helper'

class StyleguideControllerTest < ActionDispatch::IntegrationTest
  test 'style guide is not routed outside development' do
    get '/styleguide'
    assert_response :not_found
  end
end
