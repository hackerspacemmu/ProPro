FactoryBot.define do
  factory :enrolment do
    association :user
    association :course
    role { :student }
  end

  trait :lecturer do
    role { :lecturer }
  end

  trait :coordinator do
    role { :coordinator }
  end
end