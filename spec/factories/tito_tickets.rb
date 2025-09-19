FactoryBot.define do
  factory :tito_ticket do
    event
    user { nil }
    tito_id { rand(100000..999999) }
    slug { "ti_test_#{SecureRandom.alphanumeric}" }
    reference { "ABCD-1" }
    unique_url { "https://ti.to/tickets/#{slug}" }
    state { "complete" }
  end
end
