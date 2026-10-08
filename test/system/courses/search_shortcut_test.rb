require 'application_system_test_case'

class SearchShortcutTest < BrowserSystemTestCase
  setup do
    @course = create(:course)
    @coordinator = create(:enrolment, :coordinator, course: @course).user
  end

  # "/" fires KeyboardEvent
  def press_slash_until
    wait_for_turbo
    4.times do
      page.execute_script(
        'window.dispatchEvent(new KeyboardEvent("keydown", { key: "/", bubbles: true }))'
      )
      return if yield

      sleep 0.3
    end
    flunk "'/' never produced the expected outcome"
  end

  # Focus on the search bar is asserted on document.activeElement
  def assert_eventually_active(input_id)
    deadline = Capybara.default_max_wait_time
    loop do
      active = page.evaluate_script('document.activeElement && document.activeElement.id')
      return if active == input_id

      assert_operator Time.zone.now, :<, deadline,
                      "expected ##{input_id} to become the active element (was #{active.inspect})"
      sleep 0.05
    end
  end

  test 'pressing slash focuses the search input on a tab that has one' do
    login_as @coordinator
    visit course_people_path(@course)
    assert_selector '#students-search'

    press_slash_until do
      page.evaluate_script('document.activeElement && document.activeElement.id') == 'students-search'
    end
    assert_eventually_active 'students-search'
  end

  test 'pressing slash on a tab without a search input jumps to the Groups fallback' do
    @course.update!(grouped: true)
    login_as @coordinator
    visit course_path(@course)

    press_slash_until { page.current_path == course_groups_path(@course) }
    assert_current_path course_groups_path(@course)
    assert_eventually_active 'groups-search'
  end
end
