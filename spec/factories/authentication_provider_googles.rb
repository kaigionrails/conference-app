FactoryBot.define do
  factory :authentication_provider_google do
    association :user
    sequence(:uid) { |n| "1085320000000000000#{n}" }
  end
end
