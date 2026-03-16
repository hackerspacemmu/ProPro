require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test

  include FactoryBot::Syntax::Methods

  def login_as(user, password: 'password')
    visit login_path
    fill_in 'email_address', with: user.email_address
    fill_in 'password', with: password
    click_button 'Sign In'
  end
end
