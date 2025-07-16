class CoursesController < ApplicationController
before_action :set_course_name
before_action :set_group_by_course
before_action :set_proposal 

    def viewcourse
        @course = {
            name: @course,
            group: @group,
            proposal: @proposal,
            status: @proposal.status,
            members: @group.users
        }
    end
end 

    private 
    def set_course_name
        @course = Course.find(params[:id])
    end 

    def set_group_by_course
        @group = current_user.project_groups.joins(:enrolments).find_by(enrolments: { course_id: @course.id })
    end

    def set_proposal 
        @proposal = Proposal.find_by(group_id: @group.id)
    end