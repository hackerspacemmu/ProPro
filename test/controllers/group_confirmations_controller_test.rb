require 'test_helper'

class GroupConfirmationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course, :grouped, grouping_enabled: true, grouping_open: false, group_min: 2, group_max: 4)
    @coordinator = create(:user)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @leader = create(:user)
    create(:enrolment, :student, user: @leader, course: @course)
  end

  test 'coordinator can confirm an undersized group with closed window' do
    group = create(:project_group, course: @course, confirmed: false, group_name: 'Tmp001', leader_id: @leader.id)
    create(:project_group_member, user: @leader, project_group: group)

    sign_in @coordinator
    post course_group_confirmation_path(@course, group, return_to: course_groups_path(@course))

    assert_redirected_to course_groups_path(@course)
    assert group.reload.confirmed?
    assert_equal 'G001', group.group_name
    assert_equal 'Tmp001 is now confirmed as G001.', flash[:notice]
  end

  test 'coordinator can reopen a confirmed group with closed window' do
    group = create(:project_group, course: @course, confirmed: true, group_name: 'G001', leader_id: @leader.id)
    create(:project_group_member, user: @leader, project_group: group)

    sign_in @coordinator
    delete course_group_confirmation_path(@course, group, return_to: course_groups_path(@course))

    assert_redirected_to course_groups_path(@course)
    assert_not group.reload.confirmed?
    assert_equal 'Tmp001', group.group_name
    assert_equal 'G001 is reopened as Tmp001.', flash[:notice]
  end

  test 'leader is blocked from confirming when window is closed' do
    group = create(:project_group, course: @course, confirmed: false, group_name: 'Tmp001', leader_id: @leader.id)
    create(:project_group_member, user: @leader, project_group: group)

    sign_in @leader
    post course_group_confirmation_path(@course, group)

    assert_redirected_to course_group_formation_path(@course)
    assert_not group.reload.confirmed?
    assert_equal 'The grouping window is closed.', flash[:alert]
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
