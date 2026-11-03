require 'application_system_test_case'

class GroupFormationLeaveActionTest < ApplicationSystemTestCase
  setup do
    @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true,
                                        group_min: 2, group_max: 4, student_list_finalised: false)
    @leader = create(:user)
    create(:enrolment, user: @leader, course: @course)
    @member = create(:user)
    create(:enrolment, user: @member, course: @course)
    @group = create(:project_group, course: @course, leader_id: @leader.id, group_name: 'Leave Group')
    create(:project_group_member, project_group: @group, user: @leader)
    create(:project_group_member, project_group: @group, user: @member)
  end

  test 'a confirmed group offers no leave action' do
    login_as @member

    visit course_group_formation_path(@course)
    assert_button 'Leave group'

    @group.update!(confirmed: true)
    visit course_group_formation_path(@course)
    assert_no_button 'Leave group'
  end

  # rack_test runs no JavaScript, so Turbo's cable source never reports itself
  # connected and the default visit wrapper would wait forever.
  def visit(path, **)
    page.visit(path, **)
  end
end
