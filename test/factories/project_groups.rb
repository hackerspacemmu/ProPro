FactoryBot.define do
  factory :project_group do
    association :course
    group_name { Faker::Educator.subject }
  end
end
