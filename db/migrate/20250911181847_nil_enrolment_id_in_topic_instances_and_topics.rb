class NilEnrolmentIdInTopicInstancesAndTopics < ActiveRecord::Migration[8.0]
  def change
    Topic.find_each do |topic|
      topic.update!(enrolment_id: nil)
    end

    TopicInstance.find_each do |topic_instance|
      topic_instance.update!(enrolment_id: nil)
    end
  end
end
