class CoursesController < ApplicationController

    def show
        @course = Course.find(params[:id])
        @group = current_user.project_groups.joins(:enrolments).find_by(enrolments: { course_id: @course.id })
        @project = Project.find_by(group_id: @group.id)
        @project_template = @course.project_template
        @lecturer = supervisor.projects.where(enrolment: { course_id: @course.id }).count
    end
end
