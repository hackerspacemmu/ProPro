require 'test_helper'

# groups#show — one group's participant profile (ADR 0022 phase 1). The
# behavior that matters here is scoping/authorization; the presentation is the
# old courses#profile group branch, moved verbatim.
class GroupsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course, :grouped)
    @coordinator = create(:user)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)

    @group = create(:project_group, course: @course, confirmed: true, group_name: 'Smoke Group')
  end

  test 'renders for a coordinator' do
    sign_in @coordinator
    get course_group_path(@course, @group)
    assert_response :success
    assert_select 'h1#group-name', text: 'Smoke Group'
  end

  test '404s on an ungrouped course' do
    ungrouped = create(:course)
    create(:enrolment, :coordinator, user: @coordinator, course: ungrouped)
    group = create(:project_group, course: ungrouped)

    sign_in @coordinator
    get course_group_path(ungrouped, group)
    assert_response :not_found
  end

  test 'a group from another course 404s' do
    other = create(:course, :grouped)
    other_group = create(:project_group, course: other)

    sign_in @coordinator
    get course_group_path(@course, other_group)
    assert_response :not_found
  end

  test 'groups#index hides unconfirmed groups when formation is open' do
    @course.update!(group_formation_enabled: true)
    create(:project_group, course: @course, confirmed: false, group_name: 'Tmp999')
    create(:project_group, course: @course, confirmed: true, group_name: 'G999')

    sign_in @coordinator
    get course_groups_path(@course)
    assert_response :success

    assert_select 'table', text: /G999/
    assert_select 'table', text: /Tmp999/, count: 0
    assert_select 'a', text: /Group formation/
  end

  test 'groups#index shows unconfirmed groups when formation is closed' do
    @course.update!(group_formation_enabled: true, group_formation_closes_at: 1.hour.ago)
    create(:project_group, course: @course, confirmed: false, group_name: 'Tmp999')

    sign_in @coordinator
    get course_groups_path(@course)
    assert_response :success

    assert_select 'table', text: /Tmp999/
    assert_select 'span', text: 'Not confirmed'
    assert_select 'div[role="status"]', text: /Group formation is closed/
  end

  test 'groups#index status filter for not confirmed works when closed and is ignored when open' do
    @course.update!(group_formation_enabled: true, group_formation_closes_at: 1.hour.ago)
    create(:project_group, course: @course, confirmed: false, group_name: 'Tmp999')
    create(:project_group, course: @course, confirmed: true, group_name: 'G999')

    sign_in @coordinator
    get course_groups_path(@course, status_filter: 'not_confirmed')
    assert_response :success
    assert_select 'table', text: /Tmp999/
    assert_select 'table', text: /G999/, count: 0

    # Stale not-confirmed filter ignored when formation is open
    @course.update!(group_formation_closes_at: nil)
    get course_groups_path(@course, status_filter: 'not_confirmed')
    assert_response :success
    assert_select 'table', text: /G999/
    assert_select 'table', text: /Tmp999/, count: 0
  end

  test 'coordinator sees manage column on groups table' do
    @course.update!(group_formation_enabled: true)
    sign_in @coordinator
    get course_groups_path(@course)
    assert_response :success

    assert_select 'th span.sr-only', text: 'Manage'
    assert_select 'button, a', text: 'Manage'
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
