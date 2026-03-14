FactoryBot.define do
  factory :topic, class: Topic do
    association :course
    owner { association :user, is_staff: true }
  end
end