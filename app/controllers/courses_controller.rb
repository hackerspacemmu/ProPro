class CoursesController < ApplicationController

    def show
        @course = Course.find(params[:id])
        
        if @course.grouped?
            @group = current_user.project_groups.joins(:project_group_members).find_by(project_group_members: {course_id: @course.id})
            @project = Project.find_by(owner: @group)
            @group_list = @course.project_group

        else:
            @group = nil
            @project = Project.find_by(owner: current_user, course_id: @course.id)

        @description = @course.project_template.description
        @student_list = @course.enrolments.where(role: :student).includes(:user).map(&:user)
        @lecturers = @course.enrolments.where(role: :lecturer).includes(:user).map(&:user)
        @topic_list = @course.projects.joins(:ownership).where(ownerships: { ownership_type: :lecturer })
        @students_with_projects = @student_list.select do |student|students_with_projects.include?(student.id)
        @students_without_projects = @student_list.reject do |student|students_with_projects.include?(student.id)

    end
    private 
    def students_with_projects
        Project.joins(:ownership).where(course_id: @course.id, ownerships: { ownership_type: :student, owner_type: "User" })
        .where.not(status: :rejected)
        .pluck("ownerships.owner_id")
    end


end
