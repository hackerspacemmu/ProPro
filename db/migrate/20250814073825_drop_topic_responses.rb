class DropTopicResponses < ActiveRecord::Migration[8.0]
  def change
    drop_table :topic_responses
  end
end
