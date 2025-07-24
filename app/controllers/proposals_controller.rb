class ProposalsController < ApplicationController

  def index
  @courses = Current.user.courses
  @course = Course.find(params[:course_id]) 
    @proposals = @course.projects.joins(:enrolment)
                        .where(enrolments: { course_id: @course.id, user_id: current_user.id })
  end

def show
  @courses = Current.user.courses
  @course = Course.find(params[:course_id]) 

  @proposal = @course.projects.find(params[:id])
  @instances = @proposal.project_instances.order(version: :desc)
  @owner = @proposal.ownership&.owner
  @status = @proposal.status

  @type = @proposal.ownership&.ownership_type

  @members = @owner.is_a?(ProjectGroup) ? @owner.users : [@owner]


  


  if @owner.is_a?(ProjectGroup)
  @members = @owner.users  #All memebers if group project
else
  @members = [@owner] #individual
end


  # Determine which version to show (default: newest, i.e., index 0)
  index = params[:version].to_i
  index = 0 if index >= @instances.size || index < 0

  @current_instance = @instances[index]

  @fields = @current_instance.project_instance_fields.includes(:project_template_field)


end

def change_status
  @courses = Current.user.courses
  @course = Course.find(params[:course_id]) 
  @proposal = @course.projects.find(params[:id])

  if current_user.is_staff
    @proposal.update(status: Project.statuses.key(params[:status].to_i))
    redirect_to course_proposal_path(@course, @proposal), notice: "Status updated."
  else
    redirect_to course_proposal_path(@course, @proposal), alert: "You are not authorized to perform this action."
  end
end

def edit
  @course = Course.find(params[:course_id])
  @proposal = @course.projects.find(params[:id])   #for going back
  #@project = @course.projects.find(params[:id]) #idk why but i cant use proposal so project it is
  @instance = @proposal.project_instances.find(params[:id])

  # Get template fields linked to the same template as your instance
  template = ProjectTemplate.find_by(course_id: @course.id)
  @template_fields = template.project_template_fields if template
end



end
  