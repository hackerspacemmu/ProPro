FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email_address { Faker::Internet.unique.email }
    password { 'password' }
    is_staff { false }
    has_registered { true }
    instid { Faker::Alphanumeric.alphanumeric(number: 8) }

    trait :staff do
      is_staff { true }
      instid { nil }
    end
  end
end
