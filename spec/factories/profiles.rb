FactoryBot.define do
  factory :profile do
    user

    trait :with_image do
      after(:build) do |profile|
        profile.images.attach(
          io: StringIO.new(Rails.root.join("spec/assets/sample.png").read),
          filename: "sample.png",
          content_type: "image/png"
        )
      end
    end
  end
end
