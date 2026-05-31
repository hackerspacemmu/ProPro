FactoryBot.define do
  factory :project_group_invite do
    association :project_group
    association :sender, factory: :user
    kind   { :request }
    status { :pending }
  end
end
