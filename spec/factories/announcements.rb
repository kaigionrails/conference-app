FactoryBot.define do
  factory :announcement do
    event
    status { "draft" }
    published_at { nil }
  end
end
