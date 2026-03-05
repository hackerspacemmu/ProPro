FactoryBot.define do
  factory :user do
    username { Faker::Name.name }
    email_address { Faker::Internet.email }
    password { SecureRandom.base64(24) }
    is_staff { false }
    has_registered { true }
    student_id { Faker::Alphanumeric.alphanumeric(number: 8) }
  end

  trait :staff do
    is_staff { true }
    student_id { nil }
  end
end