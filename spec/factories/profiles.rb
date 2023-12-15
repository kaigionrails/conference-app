FactoryBot.define do
  factory :profile do
    user

    trait :with_image do
      after(:build) do |profile|
        profile.images.attach(
          io: StringIO.new(File.read(Rails.root.join("spec", "assets", "sample.png"))),
          filename: "sample.png",
          content_type: "image/png"
        )
      end
    end
  end
end
