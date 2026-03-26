FactoryBot.define do
  factory :topic_instance, class: TopicInstance do
    association :topic
    association :created_by, factory: :user
    version { 1 }
    status { :pending }
    title { Faker::Lorem.words(number: 3).join(' ') }
  end
end
