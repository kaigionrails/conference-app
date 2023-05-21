FactoryBot.define do
  factory :authentication_provider_github do
    user { user }
    uid { "12345678" }
  end
end
