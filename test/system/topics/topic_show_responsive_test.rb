require 'application_system_test_case'

# The topic show page carries the same comments drawer as the project show
# page, so the static wiring is asserted here the way
# project_show_responsive_test.rb does it. The drawer and its resize handle
# are shared chrome; only their behaviour is JavaScript, and that stays in the
# selenium comments_panel_resize_test.
class TopicShowResponsiveTest < ApplicationSystemTestCase
  setup do
    @course   = create(:course)
    @lecturer = create(:user, :staff)

    create(:enrolment, :lecturer, user: @lecturer, course: @course)

    @topic    = create(:topic, course: @course, owner: @lecturer)
    @instance = create(:topic_instance, topic: @topic, created_by: @lecturer, version: 1, status: :pending)
  end

  test 'show page exposes the comments drawer trigger, panel, backdrop and resize handle' do
    login_as(@lecturer)
    visit course_topic_path(@course, @topic)

    assert_selector 'button[data-comments-drawer-target="trigger"]'
    assert_selector "[data-comments-drawer-target='panel']"
    assert_selector "[data-comments-drawer-target='backdrop']"
    # The drag-resize handle is wired up here too; its behaviour is a
    # JavaScript concern, so only the static wiring is asserted under
    # rack_test (the drag itself is exercised by the selenium
    # comments_panel_resize_test).
    assert_selector '[role="separator"][data-comments-panel-target="handle"]'
  end
end
