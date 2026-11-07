require 'test_helper'

class ProjectGroupRaceTest < ActionDispatch::IntegrationTest
  include TestSupport::NonTransactional

  setup do
    @course = create(:course, :grouped, grouping_enabled: true, grouping_open: true,
                                        group_min: 2, group_max: 4, student_list_finalised: false)
    @leader = create(:user)
    @member = create(:user)
    create(:enrolment, :student, user: @leader, course: @course)
    create(:enrolment, :student, user: @member, course: @course)

    @group = create(:project_group, course: @course, confirmed: true, leader_id: @leader.id)
    create(:project_group_member, project_group: @group, user: @leader)
    create(:project_group_member, project_group: @group, user: @member)

    @lecturer = create(:enrolment, :lecturer, course: @course)
    @field = @course.project_template.project_template_fields.find_by!(is_project_title: true)
  end

  test 'two concurrent project creates leave one project and an alert' do
    sessions = [session_for(@leader), session_for(@member)]
    release = Queue.new
    holder = hold_group_lock(release)
    start = Queue.new

    threads = sessions.map do |session|
      Thread.new do
        with_connection do
          start.pop
          session.post course_projects_path(@course), params: project_params
        end
      end
    end

    2.times { start << true }
    wait_for_lock_waits(2)
    release << true

    Timeout.timeout(10) { threads.each(&:value) }

    assert_equal 1, Project.where(owner: @group).count
    assert_equal(1, sessions.count { |session| session.flash[:alert] == 'Your group already has a project' })
    assert_equal(1, sessions.count { |session| session.flash[:notice] == 'Project created!' })
  ensure
    release << true if release
    (threads || []).each { |thread| thread.join(1) || thread.kill }
    holder&.join(1)
    holder&.kill
  end

  test 'reopen racing create never leaves a project on a not-confirmed group' do
    create_session = session_for(@member)
    revert_session = session_for(@leader)
    release = Queue.new
    holder = hold_group_lock(release)
    start = Queue.new

    create_thread = Thread.new do
      with_connection do
        start.pop
        create_session.post course_projects_path(@course), params: project_params
      end
    end

    revert_thread = Thread.new do
      with_connection do
        start.pop
        revert_session.delete course_group_confirmation_path(@course, @group)
      end
    end

    2.times { start << true }
    wait_for_lock_waits(2)
    release << true

    Timeout.timeout(10) do
      create_thread.value
      revert_thread.value
    end

    group = @group.reload
    assert group.project.nil? || group.confirmed?,
           'expected no project to survive on a not-confirmed group'
  ensure
    release << true if release
    [create_thread, revert_thread].compact.each { |thread| thread.join(1) || thread.kill }
    holder&.join(1)
    holder&.kill
  end

  private

  def session_for(user)
    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host! 'www.example.com'
    session.post session_path, params: { email_address: user.email_address, password: 'password' }
    session
  end

  def project_params
    { based_on_topic: "own_proposal_#{@lecturer.id}",
      fields: { @field.id.to_s => 'Group Project' } }
  end

  def hold_group_lock(release)
    held = Queue.new

    thread = Thread.new do
      with_connection do
        ProjectGroup.transaction do
          ProjectGroup.lock.find(@group.id)
          held << true
          release.pop
        end
      end
    end

    held.pop
    thread
  end
end
