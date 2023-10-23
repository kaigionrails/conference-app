FactoryBot.define do
  factory :user do
    name { "foo" }
    role { "participant" }

    trait :with_profile_image do
      after(:create) do |user|
        create(:profile, :with_image, user: user)
      end
    end
  end
end
