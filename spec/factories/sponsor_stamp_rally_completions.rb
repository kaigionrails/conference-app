FactoryBot.define do
  factory :sponsor_stamp_rally_completion do
    user
    event
    completed_at { Time.current }
  end
end
