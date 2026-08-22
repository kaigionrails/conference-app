require "rails_helper"

RSpec.describe "Admin::SocialAnnouncements", type: :request do
  let(:admin) { FactoryBot.create(:user, role: "organizer") }
  let!(:event) { FactoryBot.create(:event, slug: Event::ONGOING_EVENT_SLUG) }

  before { sign_in(admin) }

  it "rejects non-organizers" do
    sign_in(FactoryBot.create(:user, role: "participant"))
    get admin_social_announcements_path
    expect(response).to redirect_to(root_path)
  end

  describe "GET /admin/social_announcements" do
    it "lists announcements of the ongoing event" do
      FactoryBot.create(:social_announcement, event: event, campaign: "Listed one")
      get admin_social_announcements_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Listed one")
      expect(response.body).to include("Connect X")
    end

    it "defaults to the OngoingEvent when one exists" do
      ongoing = FactoryBot.create(:event, :make_ongoing, name: "Kaigi on Rails ongoing")
      FactoryBot.create(:social_announcement, event: ongoing, campaign: "Ongoing one")
      FactoryBot.create(:social_announcement, event: event, campaign: "Slug one")

      get admin_social_announcements_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ongoing one")
      expect(response.body).not_to include("Slug one")
    end
  end

  describe "POST /admin/social_announcements" do
    it "creates an announcement with the current user as creator" do
      expect {
        post admin_social_announcements_path, params: {social_announcement: {event_id: event.id, campaign: "New one", note: "memo"}}
      }.to change { SocialAnnouncement.count }.by(1)
      announcement = SocialAnnouncement.last
      expect(announcement.created_by).to eq(admin)
      expect(response).to redirect_to(admin_social_announcement_path(announcement))
    end
  end

  describe "GET /admin/social_announcements/:id" do
    let(:announcement) { FactoryBot.create(:social_announcement, :with_texts, :with_all_platforms, event: event) }

    it "renders texts, platforms, media and the posts matrix" do
      FactoryBot.create(:social_announcement_media, social_announcement: announcement, alt_text_ja: "alt")
      text = announcement.texts.first
      target = announcement.target_platforms.first
      FactoryBot.create(:social_announcement_post, :succeeded, social_announcement_text: text, social_announcement_target_platform: target, remote_url: "https://example.test/p/1")
      get admin_social_announcement_path(announcement)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("日本語の本文")
      expect(response.body).to include("https://example.test/p/1")
      expect(response.body).to include("1</span>/4 attached")
      expect(response.body).to include("Not reviewed")
      expect(response.body).to include("already posted")
    end
  end

  describe "GET /admin/social_announcements/:id when published" do
    it "disables platform, media and dispatch controls" do
      announcement = FactoryBot.create(:social_announcement, :with_texts, event: event)
      target = FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "mastodon")
      FactoryBot.create(:social_announcement_media, social_announcement: announcement)
      announcement.texts.each do |text|
        FactoryBot.create(:social_announcement_post, :succeeded, social_announcement_text: text, social_announcement_target_platform: target)
      end
      announcement.sync_published_at!
      expect(announcement.published_at).to be_present

      get admin_social_announcement_path(announcement)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(admin_social_announcement_target_platforms_path(announcement) + '" method="post"')
      expect(response.body).not_to include("Attach")
      expect(response.body).not_to include("Remove this media?")
      expect(response.body).not_to include("Post now?")
      expect(response.body.scan("already published").size).to eq(3)
    end
  end

  describe "texts" do
    let(:announcement) { FactoryBot.create(:social_announcement, event: event) }

    it "creates and updates a text" do
      post admin_social_announcement_texts_path(announcement), params: {social_announcement_text: {locale: "ja", body: "初稿"}}
      text = announcement.texts.find_by!(locale: "ja")
      expect(text.body).to eq("初稿")

      patch admin_social_announcement_text_path(announcement, text), params: {social_announcement_text: {body: "改稿"}}
      expect(text.reload.body).to eq("改稿")
    end

    it "rejects over-limit body and re-renders the column with the error" do
      post admin_social_announcement_texts_path(announcement), params: {social_announcement_text: {locale: "ja", body: "あ" * 141}}
      expect(announcement.texts.count).to eq(0)
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("social_announcement_text_ja")
      expect(response.body).to match(/280/)
    end
  end

  describe "hashtag warning" do
    let(:announcement) { FactoryBot.create(:social_announcement, event: event) }

    it "warns when #kaigionrails is missing or not delimited, and hides the warning when properly delimited" do
      # 前後に空白の無い「繋がった#kaigionrailsです」はハッシュタグとして成立しないので警告対象
      FactoryBot.create(:social_announcement_text, social_announcement: announcement, locale: "ja", body: "繋がった#kaigionrailsです")
      FactoryBot.create(:social_announcement_text, social_announcement: announcement, locale: "en", body: "Visit us!
#KaigiOnRails")
      get admin_social_announcement_path(announcement)
      warnings = response.body.scan(/<p[^>]*data-admin--social-announcement-target="hashtagWarning"[^>]*>/)
      expect(warnings.length).to eq(2)
      expect(warnings[0]).not_to include("hidden")
      expect(warnings[1]).to include("hidden")
    end
  end

  describe "mention warning" do
    let(:announcement) { FactoryBot.create(:social_announcement, event: event) }

    it "warns when the body contains a mention and stays hidden otherwise" do
      FactoryBot.create(:social_announcement_text, social_announcement: announcement, locale: "ja", body: "登壇者 @speaker@ruby.social さん #kaigionrails")
      FactoryBot.create(:social_announcement_text, social_announcement: announcement, locale: "en", body: "mail me at foo@example.com #kaigionrails")
      get admin_social_announcement_path(announcement)
      warnings = response.body.scan(/<p[^>]*data-admin--social-announcement-target="mentionWarning"[^>]*>/)
      expect(warnings.length).to eq(2)
      expect(warnings[0]).not_to include("hidden")
      expect(warnings[1]).to include("hidden")
    end
  end

  describe "POST text_reviews" do
    let(:announcement) { FactoryBot.create(:social_announcement, :with_texts, event: event) }

    it "approves the current body" do
      text = announcement.texts.first
      post admin_social_announcement_text_reviews_path(announcement), params: {social_announcement_text_id: text.id}
      expect(text.reload).to be_approved
      expect(text.latest_review.reviewed_by).to eq(admin)
    end
  end

  describe "PATCH target_platforms" do
    let(:announcement) { FactoryBot.create(:social_announcement, :with_texts, event: event) }

    it "adds and removes platforms" do
      patch admin_social_announcement_target_platforms_path(announcement), params: {social_announcement: {platforms: ["x", "mastodon"]}}
      expect(announcement.target_platforms.pluck(:platform)).to contain_exactly("x", "mastodon")
      patch admin_social_announcement_target_platforms_path(announcement), params: {social_announcement: {platforms: ["mastodon"]}}
      expect(announcement.target_platforms.pluck(:platform)).to contain_exactly("mastodon")
    end

    it "does not remove a posted platform" do
      target = FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "mastodon")
      FactoryBot.create(:social_announcement_post, social_announcement_text: announcement.texts.first, social_announcement_target_platform: target)
      patch admin_social_announcement_target_platforms_path(announcement), params: {social_announcement: {platforms: []}}
      expect(announcement.target_platforms.pluck(:platform)).to eq(["mastodon"])
      expect(flash[:alert]).to match(/already has posts/)
    end
  end

  describe "media" do
    let(:announcement) { FactoryBot.create(:social_announcement, event: event) }
    let(:file) { Rack::Test::UploadedFile.new(Rails.root.join("spec/assets/sample.png"), "image/png") }

    it "attaches, updates alt text and removes" do
      post admin_social_announcement_media_path(announcement), params: {social_announcement_media: {file: file}}
      medium = announcement.media.reload.first
      expect(medium.file).to be_attached

      patch admin_social_announcement_medium_path(announcement, medium), params: {social_announcement_media: {alt_text_ja: "new alt", alt_text_en: "new alt en", position: 3}}
      expect(medium.reload.alt_text_ja).to eq("new alt")
      expect(medium.alt_text_en).to eq("new alt en")
      expect(medium.position).to eq(3)

      delete admin_social_announcement_medium_path(announcement, medium)
      expect(announcement.media.count).to eq(0)
    end

    it "re-renders the media card with the error when alt text is invalid" do
      medium = FactoryBot.create(:social_announcement_media, social_announcement: announcement)
      patch admin_social_announcement_medium_path(announcement, medium), params: {social_announcement_media: {alt_text_ja: "a" * 1001}}
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("social_announcement_medium_#{medium.id}")
      expect(medium.reload.alt_text_ja).to be_nil
    end

    it "rejects a fifth media" do
      4.times { |i| FactoryBot.create(:social_announcement_media, social_announcement: announcement, position: i) }
      post admin_social_announcement_media_path(announcement), params: {social_announcement_media: {file: file}}
      expect(announcement.media.count).to eq(4)
      expect(flash[:alert]).to match(/max 4/)
    end
  end

  describe "POST dispatch" do
    let(:announcement) { FactoryBot.create(:social_announcement, :with_texts, event: event) }

    before { FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "mastodon") }

    it "enqueues jobs when fully approved" do
      announcement.texts.each { |t| SocialAnnouncementTextReview.create_for!(t, reviewer: admin) }
      expect {
        post admin_social_announcement_dispatch_path(announcement)
      }.to have_enqueued_job(SocialAnnouncementPostJob).exactly(2).times
      expect(flash[:success]).to be_present
    end

    it "shows an error when not approved" do
      expect {
        post admin_social_announcement_dispatch_path(announcement)
      }.not_to have_enqueued_job(SocialAnnouncementPostJob)
      expect(flash[:alert]).to match(/not fully approved/)
    end
  end
end
