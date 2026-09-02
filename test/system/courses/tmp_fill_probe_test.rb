require 'application_system_test_case'

class TmpFillProbeTest < ApplicationSystemTestCase
  self.use_transactional_tests = false

  driven_by :selenium, using: :headless_chrome, screen_size: [1280, 900]

  setup do
    @course = create(:course)
    @coordinator = create(:enrolment, :coordinator, course: @course).user
  end

  teardown do
    return if @course.nil?

    Course.transaction do
      template = @course.project_template
      template&.project_template_fields&.delete_all
      template&.delete

      @course.enrolments.delete_all

      @coordinator.sessions.delete_all
      @coordinator.otp&.delete

      @course.delete
      @coordinator.delete
    end
  end

  def login_as(user, password: 'password')
    super
    assert_current_path root_path, wait: Capybara.default_max_wait_time * 2
  end

  def click_tab(name)
    find_button(name).evaluate_script('this.click()')
    sleep 0.15
  end

  def dump(label)
    state = evaluate_script("Array.from(document.querySelectorAll('[data-tabs-target=\"tab\"]')).map(t => { const cs = getComputedStyle(t); return { text: t.textContent.trim(), selected: t.getAttribute('aria-selected'), cls: t.className, bg: cs.backgroundColor }; })")
    Rails.logger.info("=== #{label} ===")
    state.each { |t| Rails.logger.info("  #{t['text']}: aria=#{t['selected']} bg=#{t['bg']}  #{t['cls']}") }
  end

  test 'probe fill freeze' do
    login_as @coordinator

    Rails.logger.info('--- SCENARIO A: fresh load, no ?tab ---')
    visit course_path(@course)
    dump('A initial')
    click_tab 'To Review'
    dump('A after click To Review')
    click_tab 'Topics'
    dump('A after click Topics')

    Rails.logger.info('--- SCENARIO B: load baked with ?tab=to_review (simulated refresh) ---')
    visit course_path(@course, tab: 'to_review')
    dump('B initial (baked to_review)')
    click_tab 'Topics'
    dump('B after click Topics')
    click_tab 'People'
    dump('B after click People')

    assert true
  end
end
