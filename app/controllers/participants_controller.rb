class ParticipantsController < ApplicationController
  before_action :settings_course
  before_action :set_participant, only: [:show]

  def show
    # @participant will be either a User or ProjectGroup
    # @course is already set
  end


  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_participant
    # Determine if this is a student or group based on the ID pattern
    # or you could use a type parameter
    if @course.grouped?
      # Try to find as a group first, then as a student
      @participant = @course.project_groups.find_by(id: params[:id]) ||
                    @course.enrolments.joins(:user).find_by(users: { id: params[:id] })&.user
    else
      # Individual course, so it's definitely a student
      @participant = @course.enrolments.joins(:user).find_by(users: { id: params[:id] })&.user
    end
    
    redirect_to @course, alert: "Participant not found" unless @participant
  end
end