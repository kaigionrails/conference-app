FactoryBot.define do
  factory :announcement do
    event
    title { "Test announcement" }
    status { "draft" }
    published_at { nil }

    trait :published do
      status { "published" }
      published_at { Time.current }
    end
  end
end
