# test/services/supervisor_capacity_calculator_test.rb
require 'test_helper'

class SupervisorCapacityCalculatorTest < ActiveSupport::TestCase
  test 'calculate returns capacity info for a lecturer enrolment' do
    course = FactoryBot.create(:course, supervisor_projects_limit: 10)
    lecturer = FactoryBot.create(:user)
    enrolment = FactoryBot.create(:enrolment, :lecturer, course: course, user: lecturer)

    result = Queries::SupervisorCapacityCalculator.new(course).execute
    lecturer_capacity = result.lecturer_capacities.find { |lc| lc.enrolment.id == enrolment.id }

    assert_equal 0, lecturer_capacity.approved_count
    assert_equal 0, lecturer_capacity.pending_count
    assert_equal course.supervisor_projects_limit, lecturer_capacity.effective_cap
    assert_equal false, lecturer_capacity.at_capacity?
  end
end
