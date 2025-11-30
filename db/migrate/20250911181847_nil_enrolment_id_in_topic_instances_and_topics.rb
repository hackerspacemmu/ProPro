class NilEnrolmentIdInTopicInstancesAndTopics < ActiveRecord::Migration[8.0]
  def change
    change_column_null :projects, :enrolment_id, true
    change_column_null :project_instances, :enrolment_id, true

    Topic.find_each do |topic|
      topic.update!(enrolment_id: nil)
    end

    TopicInstance.find_each do |topic_instance|
      topic_instance.update!(enrolment_id: nil)
    end
  end
end
