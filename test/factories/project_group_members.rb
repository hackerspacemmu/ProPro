FactoryBot.define do
  factory :project_group_member do
    association :user
    association :project_group
  end
end
