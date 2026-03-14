FactoryBot.define do
  factory :project_instance do
    association :project
    association :enrolment
    association :created_by, factory: :user
    version { 1 }
    status { :pending }
    title { Faker::Lorem.words(number: 3).join(' ') }
  end
end