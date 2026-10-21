module VersionBrowsing
  extend ActiveSupport::Concern

  def load_versions(instances)
    @instances = instances
    @index = params[:version].present? ? params[:version].to_i : @instances.size
    @index = @instances.size if @index <= 0 || @index > @instances.size

    @current_instance = @instances[@index - 1]
    @current_version = @index
    @latest_version = @instances.size

    @current_fields = fields_for(@current_instance)
    @next_fields = nil

    if @index < @instances.size
      @next_instance = @instances[@index]
      @next_fields = fields_for(@next_instance)
    end

    load_compare_pair
  end

  private

  def load_compare_pair
    @compare_index = @index
    @compare_fields = @current_fields
    @compare_next_fields = @next_fields

    return unless @index == @instances.size && @instances.size > 1

    previous_instance = @instances[@index - 2]
    @compare_index = @index - 1
    @compare_fields = fields_for(previous_instance)
    @compare_next_fields = @current_fields
  end

  def fields_for(instance)
    instance.project_instance_fields
            .includes(:project_template_field)
            .order(project_template_field_id: :asc)
  end
end
