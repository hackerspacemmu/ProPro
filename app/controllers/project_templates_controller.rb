class ProjectTemplatesController < ApplicationController
  before_action :set_course
  before_action :set_project_template
  before_action :only_authorise_coordinator

  def update
    if @project_template.update(project_template_params)
      redirect_to edit_course_project_template_path(@course), notice: "Template updated"
    else
      flash.now[:alert] = "Please correct the errors below before saving."
      render :edit
    end
  rescue
    render :edit
  end

  def edit
    @project_template = @course.project_template
  end


  private 

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_project_template
    @project_template = @course.project_template 
  end 

  def project_template_params
    params.require(:project_template).permit(
      :description,
      project_template_fields_attributes: [
        :id,
        :label,
        :hint,
        :field_type,
        :applicable_to,
        :_destroy,
        { options: [] }
      ]
    )
  end

  def only_authorise_coordinator
    unless @course.coordinators.pluck(:id).include? Current.user.id
      redirect_back_or_to "/", alert: "Not authorised"
      return
    end
  end
end
