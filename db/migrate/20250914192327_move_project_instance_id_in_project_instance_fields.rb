class MoveProjectInstanceIdInProjectInstanceFields < ActiveRecord::Migration[8.0]
  def up
    ActiveRecord::Base.transaction do
      ProjectInstanceField.find_each do |project_instance_field|
        # The seeds don't need this migration but live does
        if project_instance_field.project_instance_id.nil?
          next
        end

        topic_instance = TopicInstance.find_by(id: project_instance_field.project_instance_id)
        project_instance = ProjectInstance.find_by(id: project_instance_field.project_instance_id)

        if topic_instance
          project_instance_field.update!(instance: topic_instance)
        elsif project_instance
          project_instance_field.update!(instance: project_instance)
        else
          raise StandardError
        end
      end
    end
  end
end
