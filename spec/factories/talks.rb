FactoryBot.define do
  factory :talk do
    event
    sequence(:title) { |n| "awesome talk ep.#{n}" }
    sequence(:abstract) { |n| "awesome talk ep.#{n}. This is awesome talk. Enjoy it!" }
    start_at { Time.zone.now.beginning_of_hour }
    duration_minutes { 30 }
    track { "room 1" }
  end
end
