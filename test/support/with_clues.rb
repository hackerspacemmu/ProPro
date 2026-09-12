# Dump the browser's console log and the page HTML whenever a system test
# fails, so a CI-only failure carries the JS/log context needed to debug it —
# the default screenshot alone is often not enough. Fault-tolerant by design:
# it only ever runs on a failure, and its own dumps must never mask the
# underlying failure.
#
# Mirrors "Sustainable Web Development with Rails" §12.6.3.
module TestSupport
  module WithClues
    # Wrap the whole test run (setups, body, teardowns) so any failure path
    # passes through the clue dump. Overriding `run` lets us do this without
    # colliding with ActiveSupport::TestCase's `around` callback DSL.
    def run(*)
      with_clues { super }
    end

    private

    def with_clues
      yield
    rescue Exception => e # rubocop:disable Lint/RescueException -- must surface every failure path, not just StandardError
      puts "[ with_clues ] Test failed: #{e.class}: #{e.message}"
      dump_browser_logs
      dump_page_html
      raise
    end

    def dump_browser_logs
      return puts "[ with_clues ] NO BROWSER LOGS: page.driver #{page.driver.class} does not respond to #browser" unless page.driver.respond_to?(:browser)
      return puts "[ with_clues ] NO BROWSER LOGS: page.driver.browser #{page.driver.browser.class} does not respond to #manage" unless page.driver.browser.respond_to?(:manage)
      return puts "[ with_clues ] NO BROWSER LOGS: page.driver.browser.manage #{page.driver.browser.manage.class} does not respond to #logs" unless page.driver.browser.manage.respond_to?(:logs)

      puts '[ with_clues ] Browser Logs {'
      page.driver.browser.manage.logs.get(:browser).each do |log|
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
