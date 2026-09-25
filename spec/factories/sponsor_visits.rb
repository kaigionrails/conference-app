FactoryBot.define do
  factory :sponsor_visit do
    user
    event
    sponsor_key { "example.com" }
  end
end
