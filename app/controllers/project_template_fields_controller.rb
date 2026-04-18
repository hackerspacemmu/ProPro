class ProjectTemplateFieldsController < ApplicationController
  before_action :set_field
  before_action :authorize_coordinator

  def move
    if @field.insert_at(move_params[:position].to_i)
      head :no_content
    else
      render json: { error: 'Could not move field' }, status: :unprocessable_entity
    end
  end

  private

  def set_field
    @field = ProjectTemplateField.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Field not found' }, status: :not_found
  end

  def authorize_coordinator
    @course = @field.project_template&.course

    if @course
      authorize @course, :update?
    else
      render json: { error: 'Course not found' }, status: :unprocessable_entity
    end
  end

  def move_params
    params.expect(project_template_field: [:position])
  end
end
