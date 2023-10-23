FactoryBot.define do
  factory :announcement do
    event
    title { "Test announcement" }
    status { "draft" }
    published_at { nil }
  end
end
