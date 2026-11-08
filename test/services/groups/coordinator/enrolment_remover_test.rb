require 'test_helper'

module Groups
  module Coordinator
    class EnrolmentRemoverTest < ActiveSupport::TestCase
      test 'still removes the enrolment when the membership is already gone' do
        course = create(:course, :grouped)
        student = create(:user)
        enrolment = create(:enrolment, user: student, course: course)
        group = create(:project_group, course: course, leader_id: student.id)
        membership = create(:project_group_member, project_group: group, user: student)
        membership.destroy!

        result = EnrolmentRemover.new(enrolment).remove!

        assert result.removed?
        assert_not Enrolment.exists?(enrolment.id)
      end

      test 'still removes the enrolment when the group is already gone' do
        course = create(:course, :grouped)
        student = create(:user)
        enrolment = create(:enrolment, user: student, course: course)
        group = create(:project_group, course: course, leader_id: student.id)
        create(:project_group_member, project_group: group, user: student)
        group.destroy!

        result = EnrolmentRemover.new(enrolment).remove!

        assert result.removed?
        assert_not Enrolment.exists?(enrolment.id)
      end

      test 'still removes the enrolment when member removal reports the group is gone' do
        course = create(:course, :grouped)
        student = create(:user)
        enrolment = create(:enrolment, user: student, course: course)
        group = create(:project_group, course: course, leader_id: student.id)
        create(:project_group_member, project_group: group, user: student)
        blocked_result = Groups::Coordinator::MemberRemover::Result.new(
          outcome: :blocked, blocked_reason: :group_gone
        )
        fake_remover = Object.new
        fake_remover.define_singleton_method(:remove!) { blocked_result }

        Groups::Coordinator::MemberRemover.stub(:new, fake_remover) do
          result = EnrolmentRemover.new(enrolment).remove!

          assert result.removed?
        end

        assert_not Enrolment.exists?(enrolment.id)
      end

      test 'rolls back the group removal when destroying the enrolment fails' do
        course = create(:course, :grouped)
        student = create(:user)
        enrolment = create(:enrolment, user: student, course: course)
        group = create(:project_group, course: course, leader_id: student.id)
        membership = create(:project_group_member, project_group: group, user: student)

        enrolment.stub(:destroy!, -> { raise 'boom' }) do
          assert_raises(RuntimeError) { EnrolmentRemover.new(enrolment).remove! }
        end

        assert Enrolment.exists?(enrolment.id)
        assert ProjectGroupMember.exists?(membership.id)
        assert ProjectGroup.exists?(group.id)
      end
    end
  end
end
