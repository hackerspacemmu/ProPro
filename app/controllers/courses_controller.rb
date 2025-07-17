class CoursesController < ApplicationController

    def show
        @course = Course.find(params[:id])
        @group = current_user.project_groups.joins(:enrolments).find_by(enrolments: { course_id: @course.id })
        @proposal = Proposal.find_by(group_id: @group.id)
    end
end
