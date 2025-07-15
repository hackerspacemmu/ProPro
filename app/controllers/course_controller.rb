class SubjectsController < ApplicationController
before_action :set_course
before_action :set_group_by_course
before_action :set_proposal 

    def viewcourse
        @status = @proposal.status
        @members = @group.users 
    end 

    private 
    def set_course
        @course = Course.find(params[:id])
    end 

    def set_group_by_course
        @group = current_user.groups.joins(:enrollments).find_by(enrollments: { course_id: @course.id })
    end

    def set_proposal 
        @proposal = Proposal.find_by(group_id: @group.id)
    end 




