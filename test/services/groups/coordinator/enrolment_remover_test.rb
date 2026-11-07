require 'test_helper'

module Groups
  module Coordinator
    class EnrolmentRemoverTest < ActiveSupport::TestCase
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
