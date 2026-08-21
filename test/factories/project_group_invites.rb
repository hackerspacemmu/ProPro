FactoryBot.define do
  factory :project_group_invite do
    association :project_group
    association :sender, factory: :user
    association :recipient, factory: :user
    kind   { :direct_request }
    status { :pending }
  end
end
