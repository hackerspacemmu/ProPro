class ProjectTemplatesController < ApplicationController
before_action :set_course
before_action :set_project_template

  TEMPLATE_FIELD_PARAMS = %i[
    id
    label
    hint
    field_type
    applicable_to
    _destroy
  ].freeze

  def new
    if @course.project_template
      @project_template = @course.project_template 
    else
      @project_template = @course.build_project_template
    end 
    @project_template.project_template_fields.build
  end

  def create 
    @project_template = @course.build_project_template(project_template_params)
    if @project_template.save
      redirect_to edit_course_project_template_path(@course)
    else
      render :new
    end 
  end

  def update
    if @project_template.update(project_template_params)
      redirect_to edit_course_project_template_path(@course)
    else
      render :edit
    end
  end

  def edit
  end



  private 

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_project_template
    @project_template = @course.project_template 
  end 

  def project_template_params
    params.require(:project_template).permit(:description, project_template_fields_attributes: TEMPLATE_FIELD_PARAMS + [{options: []}])
  end
end