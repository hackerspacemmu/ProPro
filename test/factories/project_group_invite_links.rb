FactoryBot.define do
  factory :project_group_invite_link do
    association :project_group
    association :sender, factory: :user
    token { SecureRandom.urlsafe_base64(8) }
    expires_at { 24.hours.from_now }
  end
end
