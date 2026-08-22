FactoryBot.define do
  factory :project_group do
    association :course
    group_name { Faker::Lorem.unique.word }
    confirmed { false }
    locked { false }
  end
end
