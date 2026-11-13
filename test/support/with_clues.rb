# Dump the browser's console log and the page HTML whenever a system test
# fails, so a CI-only failure carries the JS/log context needed to debug it —
# the default screenshot alone is often not enough. Fault-tolerant by design:
# it only ever runs on a failure, and its own dumps must never mask the
# underlying failure.
#
# Mirrors "Sustainable Web Development with Rails" §12.6.3.
module TestSupport
  module WithClues
    # Minitest records failures during the test body, so before_teardown sees
    # them while Capybara's session (and browser logs) still exist.
    def before_teardown
      with_clues if failures.any?
    ensure
      super
    end

    private

    def with_clues
      failures.each do |failure|
        puts "[ with_clues ] Test failed: #{failure.class}: #{failure.message}"
      end
      dump_browser_logs
      dump_page_html
    end

    def dump_browser_logs
      return puts "[ with_clues ] NO BROWSER LOGS: page.driver #{page.driver.class} does not respond to #browser" unless page.driver.respond_to?(:browser)

      browser = page.driver.browser
      return puts "[ with_clues ] NO BROWSER LOGS: #{browser.class} does not respond to #logs" unless browser.respond_to?(:logs)

      puts '[ with_clues ] Browser Logs {'
      browser.logs.get(:browser).each do |log|
        puts "  #{log.level}: #{log.message}"
      end
      puts '[ with_clues ] } END Browser Logs'
    rescue StandardError => e
      puts "[ with_clues ] browser log dump failed: #{e.class}: #{e.message}"
    end

    def dump_page_html
      puts '[ with_clues ] HTML {'
      puts page.html
      puts '[ with_clues ] } END HTML'
    rescue StandardError => e
      puts "[ with_clues ] page HTML dump failed: #{e.class}: #{e.message}"
    end
  end
end
