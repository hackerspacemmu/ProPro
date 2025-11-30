class FixBorkedTopicInstances < ActiveRecord::Migration[8.0]
  def change
    # there are remaining topics that start with version 0 before we changed it
    # the mismatch is making the comments not go through
    borked_topics = []

    TopicInstance.find_each do |topic_instance|
      if topic_instance.version == 0
        borked_topics << topic_instance.topic
      end
    end

    borked_topics.each do |topic|
      topic.topic_instances.sort_by(&:created_at).reverse.each do |topic_instance|
        topic_instance.version += 1
        topic_instance.save!
      end
    end
  end
end
