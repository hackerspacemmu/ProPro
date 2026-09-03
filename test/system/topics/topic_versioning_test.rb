require 'application_system_test_case'

class TopicVersioningTest < ApplicationSystemTestCase
  setup do
    @course   = create(:course)
    @lecturer = create(:user, is_staff: true)

    create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @topic      = create(:topic, course: @course, owner: @lecturer)
    @instance_1 = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 1, status: :pending)
    @instance_2 = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 2, status: :pending)
  end

  test 'defaults to latest version on page load' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    version_select = find('[data-controller="version-select"]')
    selected_option = version_select.find('option[selected]')
    assert selected_option.text.include?('2 of 2'), "Expected '2 of 2 (Current)' to be selected, got: #{selected_option.text}"
  end

  test 'selecting version 1 navigates to previous version' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    select '1 of 2', from: version_select_id
    assert_current_path course_topic_path(@course, @topic, version: 1)
  end

  test 'selecting version 2 navigates to next version' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic, version: 1)

    select '2 of 2 (Current)', from: version_select_id
    assert_current_path course_topic_path(@course, @topic, version: 2)
  end

  test 'on version 1, dropdown shows versions bounded correctly with version 1 selected' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic, version: 1)

    version_select = find('[data-controller="version-select"]')
    options = version_select.all('option')
    assert_equal 2, options.length
    assert options[0].text.include?('1 of 2')
    assert options[0].selected?
    assert options[1].text.include?('2 of 2 (Current)')
  end

  test 'on latest version, dropdown shows all versions with latest selected' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    version_select = find('[data-controller="version-select"]')
    options = version_select.all('option')
    assert_equal 2, options.length
    assert options.last.text.include?('2 of 2 (Current)')
    assert options.last.selected?
  end

  private

  def version_select_id
    find('[data-controller="version-select"]')[:id]
  end
end
