FactoryBot.define do
  factory :authentication_provider_github do
    association :user
    uid { "12345678" }
  end
end
