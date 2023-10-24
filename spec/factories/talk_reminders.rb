FactoryBot.define do
  factory :talk_reminder do
    user
    talk
    scheduled_at { 1.hour.since }
    sent_at { nil }
  end
end
