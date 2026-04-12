FactoryBot.define do
  factory :project do
    association :course
    association :supervisor_enrolment, factory: :enrolment
    owner { association :user }
    owner_type { 'User' }
    status { :pending }
  end
end
