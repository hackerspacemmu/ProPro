require 'test_helper'
require 'tempfile'

class GroupImportTest < ActionDispatch::IntegrationTest
  setup do
    @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true,
                                        group_min: 2, group_max: 4)
    @coordinator = create(:user, :staff)
    create(:enrolment, :coordinator, user: @coordinator, course: @course)
    @lecturer = create(:user, :staff)
    @lecturer_enrolment = create(:enrolment, :lecturer, user: @lecturer, course: @course)
    sign_in @coordinator
  end

  test 'imported groups are confirmed, led and ready for project creation' do
    import_csv <<~CSV
      Group,Last name,ID number,Email address
      Team A,Alpha,S-1001,alice-team-a@example.com
      Team A,Beta,S-1002,beta-team-a@example.com
      Team B,Gamma,S-1003,gamma-team-b@example.com
    CSV

    assert_redirected_to course_path(@course)

    team_a = @course.project_groups.find_by!(group_name: 'Team A')
    team_b = @course.project_groups.find_by!(group_name: 'Team B')

    [team_a, team_b].each do |group|
      assert group.confirmed?
      assert group.leader_id.present?
      assert_equal [@course.id], group.project_group_members.distinct.pluck(:course_id)
    end

    assert_equal 'Alpha', team_a.users.find(team_a.leader_id).name
  end

  test 'an imported student can create a project' do
    member = create(:user, name: 'Alice', email_address: 'alice-import@example.com', instid: '1001')
    create(:enrolment, :student, user: member, course: @course)

    import_csv <<~CSV
      Group,Last name,ID number,Email address
      Team A,Alice,S-1001,alice-import@example.com
    CSV

    sign_in member
    field = @course.project_template.project_template_fields.find_by!(is_project_title: true)

    assert_difference 'Project.count', 1 do
      post course_projects_path(@course), params: {
        based_on_topic: "own_proposal_#{@lecturer_enrolment.id}",
        fields: { field.id.to_s => 'Imported Project' }
      }
    end

    project = Project.find_by!(owner: member.project_groups.find_by!(course: @course))
    assert_redirected_to course_project_path(@course, project)
    assert_equal 'Imported Project', project.current_instance.title
  end

  test 're-importing a student who is already grouped does not create an empty or leaderless group' do
    import_csv <<~CSV
      Group,Last name,ID number,Email address
      Team A,Alice,S-1001,alice-reimport@example.com
    CSV

    import_csv <<~CSV
      Group,Last name,ID number,Email address
      Team B,Alice,S-1001,alice-reimport@example.com
      Team B,Bob,S-1002,bob-reimport@example.com
    CSV

    assert_redirected_to course_path(@course)
    follow_redirect!

    team_a = @course.project_groups.find_by!(group_name: 'Team A')
    team_b = @course.project_groups.find_by!(group_name: 'Team B')
    alice = User.find_by!(email_address: 'alice-reimport@example.com')
    bob = User.find_by!(email_address: 'bob-reimport@example.com')

    assert_match(/Alice was already in a group and wasn't moved/, flash[:alert])
    assert_equal [alice], team_a.users
    assert_equal [bob], team_b.users
    assert_equal bob.id, team_b.leader_id

    @course.project_groups.each do |group|
      assert group.project_group_members.exists?
      assert group.leader_id.present?
    end
  end

  private

  def import_csv(csv)
    post handle_add_students_course_path(@course), params: { csv_file: csv_upload(csv) }
  end

  def csv_upload(csv)
    file = Tempfile.new(['students', '.csv'])
    file.write(csv)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, 'text/csv', original_filename: 'students.csv')
  end

  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: 'password' }
  end
end
