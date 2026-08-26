FactoryBot.define do
  factory :topic, class: Topic do
    association :course
    owner { association :user }
  end
end
