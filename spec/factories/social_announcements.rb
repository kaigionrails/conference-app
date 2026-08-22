FactoryBot.define do
  factory :social_announcement do
    event
    association :created_by, factory: :user
    campaign { "Test social announcement" }
    note { nil }

    trait :with_texts do
      after(:create) do |announcement|
        FactoryBot.create(:social_announcement_text, social_announcement: announcement, locale: "ja", body: "日本語の本文")
        FactoryBot.create(:social_announcement_text, social_announcement: announcement, locale: "en", body: "English body")
      end
    end

    trait :with_all_platforms do
      after(:create) do |announcement|
        SocialAnnouncement::PLATFORMS.each do |platform|
          FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: platform)
        end
      end
    end
  end

  factory :social_announcement_text do
    social_announcement
    locale { "ja" }
    body { "本文" }

    trait :approved do
      after(:create) do |text|
        SocialAnnouncementTextReview.create_for!(text, reviewer: FactoryBot.create(:user, role: "organizer"))
      end
    end
  end

  factory :social_announcement_text_review do
    social_announcement_text
    association :reviewed_by, factory: :user
    body_digest { social_announcement_text.current_body_digest }
    media_digest { social_announcement_text.social_announcement.current_media_digest }
    reviewed_at { Time.current }
  end

  factory :social_announcement_target_platform do
    social_announcement
    platform { "mastodon" }
  end

  factory :social_announcement_media do
    social_announcement
    position { 0 }
    alt_text_ja { nil }
    alt_text_en { nil }

    after(:build) do |medium|
      unless medium.file.attached?
        medium.file.attach(
          io: StringIO.new(Rails.root.join("spec/assets/sample.png").read),
          filename: "sample.png",
          content_type: "image/png"
        )
      end
    end
  end

  factory :social_announcement_post do
    social_announcement_text
    social_announcement_target_platform { FactoryBot.build(:social_announcement_target_platform, social_announcement: social_announcement_text.social_announcement) }
    status { "pending" }

    trait :succeeded do
      status { "succeeded" }
      remote_id { "123" }
      remote_url { "https://example.test/posts/123" }
      posted_body { social_announcement_text.body }
      posted_media_digest { social_announcement_text.social_announcement.current_media_digest }
      posted_at { Time.current }
    end
  end

  factory :social_oauth_token do
    platform { "x" }
    access_token { "access-token" }
    refresh_token { "refresh-token" }
    access_token_expires_at { 2.hours.from_now }
    screen_name { "testuser" }
    remote_user_id { "1" }
    scopes { SocialOauthToken::X_SCOPES.join(" ") }
    association :connected_by, factory: :user
    connected_at { Time.current }
  end
end
