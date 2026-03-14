FactoryBot.define do
  factory :project do
    association :course
    association :enrolment
    owner { association :user }
    owner_type { 'User' }
    status { :pending }
  end
end