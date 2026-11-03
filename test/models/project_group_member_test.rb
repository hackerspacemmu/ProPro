require 'test_helper'

class ProjectGroupMemberTest < ActiveSupport::TestCase
  setup do
    @course = create(:course, :grouped)
    @user = create(:user)
    @group = create(:project_group, course: @course)
    @other_group = create(:project_group, course: @course)
  end

  test 'the course is taken from the group' do
    member = ProjectGroupMember.create!(user: @user, project_group: @group)

    assert_equal @course.id, member.course_id
  end

  test 'the database refuses a second group in the same course' do
    ProjectGroupMember.create!(user: @user, project_group: @group)

    assert_raises(ActiveRecord::RecordNotUnique) do
      ProjectGroupMember.new(user: @user, project_group: @other_group, course_id: @course.id).save!(validate: false)
    end
  end

  test 'the same user can join a group in another course' do
    ProjectGroupMember.create!(user: @user, project_group: @group)
    other_course_group = create(:project_group, course: create(:course, :grouped))

    assert_nothing_raised { ProjectGroupMember.create!(user: @user, project_group: other_course_group) }
  end

  test 'add returns false when the user is already in a group of the course' do
    assert ProjectGroupMember.add(user: @user, group: @group)
    assert_not ProjectGroupMember.add(user: @user, group: @other_group)
    assert_equal 1, ProjectGroupMember.where(user_id: @user.id).count
  end

  test 'a failed add leaves the surrounding transaction usable' do
    ProjectGroupMember.create!(user: @user, project_group: @group)

    ActiveRecord::Base.transaction do
      ProjectGroupMember.add(user: @user, group: @other_group)
      assert_equal 1, ProjectGroupMember.count
    end
  end
end
