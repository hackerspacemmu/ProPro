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

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
