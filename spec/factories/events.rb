FactoryBot.define do
  factory :event do
    name { "Kaigi on Rails 2023" }
    sequence(:slug) { |n| n.to_s }
    start_date { Time.zone.parse("2023-10-27 00:00:00 +0900") }
    end_date { Time.zone.parse("2023-10-28 23:59:59 +0900") }

    trait :make_ongoing do
      after(:create) do |event|
        FactoryBot.create(:ongoing_event, event: event)
      end
    end
  end
end
