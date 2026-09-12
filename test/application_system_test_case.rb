require 'test_helper'
require 'support/with_clues'

# Headless Chrome, registered once so every browser test shares one driver
# config (book §12.6.1): any future Chrome flag or logging pref lives here and
# nowhere else. We use our own name rather than Rails' built-in :selenium so we
# can pin the browser-console logging prefs with_clues reads from.
#
# Rails' driven_by only honours `screen_size` for ITS own driver names, so the
# per-class viewport is applied in BrowserSystemTestCase#setup via resize_to.
Capybara.register_driver :propro_headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new(
    args: %w[--headless --no-sandbox --disable-dev-shm-usage --disable-gpu --window-size=1280,900]
  )
  options.add_option('goog:loggingPrefs', { browser: 'ALL' })

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test

  include FactoryBot::Syntax::Methods
  include TestSupport::WithClues

  # test_helper's `fixtures :all` loads every fixture into every test; system
  # tests build their state purely from FactoryBot, so inherit nothing. There's
  # no `fixtures :none` directive — blanking the class_attribute is the way to
  # opt out of the inherited list. DatabaseCleaner then owns all cleanup.
  self.fixture_table_names = []

  # The one we use everywhere. Turbo submits the login form via fetch; under
  # parallel load the post-login redirect can occasionally blow past a single
  # wait, so bound a few attempts (exhaustion was reproduced once at 3, hence
  # 5). Idempotent: an attempt that already landed redirects the next
  # `visit login_path` straight to root and we return early.
  def login_as(user, password: 'password')
    5.times do
      visit login_path
      return if current_path == root_path

      fill_in 'email_address', with: user.email_address
      fill_in 'password', with: password
      click_button 'Sign In'
      assert_current_path root_path, wait: Capybara.default_max_wait_time * 2
      return
    rescue Minitest::Assertion
      # Transient (slow redirect / busy DB under parallel load) -- try again.
    end

    flunk 'login_as never landed on root after 5 attempts'
  end
end

# Base for tests that need JavaScript or real geometry (book §12.6).
#
# A real browser means the app runs on an in-process Puma thread whose DB
# connection can't see rows uncommitted in the test's transaction, so these
# tests commit for real (`use_transactional_tests = false`) and DatabaseCleaner
# truncates between tests instead of relying on a rollback. Truncation is safe
# across parallel workers because each worker owns its own `*-N` test database.
class BrowserSystemTestCase < ApplicationSystemTestCase
  driven_by :propro_headless_chrome

  self.use_transactional_tests = false

  # The viewport the class runs at; mobile classes override it. Confirms our
  # per-class size before any visit (the window-size arg above is the default).
  # NOT named test_*: Minitest treats any public `test_*` method as a test.
  class_attribute :viewport_size, default: [1280, 900]

  # Turbo streams + parallel worker contention make 2s too tight; give
  # Capybara's wait-assertions room to breathe.
  Capybara.default_max_wait_time = 5

  setup do
    page.driver.browser.manage.window.resize_to(*viewport_size)

    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end

  teardown do
    DatabaseCleaner.clean
  end

  # Turbo marks <html> aria-busy between visitStarted and visitCompleted. A
  # click fired before the initial page-load visit completes races the
  # Turbo/Stimulus listeners still being attached, which is the real cause of
  # headless Chrome's "dropped first clicks". Wait for it to idle before the
  # first interaction after any visit.
  def wait_for_turbo
    Timeout.timeout(Capybara.default_max_wait_time) do
      sleep 0.02 until page.evaluate_script("document.documentElement.getAttribute('aria-busy')") != 'true'
    end
  end
end
