FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email_address { Faker::Internet.unique.email }
    password { 'password' }
    has_registered { true }
    instid { Faker::Alphanumeric.alphanumeric(number: 8) }

    trait :staff do
      instid { nil }
    end
  end
end
