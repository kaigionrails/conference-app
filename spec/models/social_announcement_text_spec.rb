require "rails_helper"

RSpec.describe SocialAnnouncementText, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:announcement) { FactoryBot.create(:social_announcement) }
  let(:reviewer) { FactoryBot.create(:user, role: "organizer") }

  describe "validation" do
    it "rejects body over weighted 280" do
      text = FactoryBot.build(:social_announcement_text, social_announcement: announcement, body: "あ" * 141)
      expect(text).not_to be_valid
      expect(text.errors[:body].first).to match(/280/)
    end

    it "accepts exactly weighted 280" do
      expect(FactoryBot.build(:social_announcement_text, social_announcement: announcement, body: "あ" * 140)).to be_valid
    end

    it "rejects duplicate locale within an announcement" do
      FactoryBot.create(:social_announcement_text, social_announcement: announcement, locale: "ja")
      expect(FactoryBot.build(:social_announcement_text, social_announcement: announcement, locale: "ja")).not_to be_valid
    end
  end

  describe "#approved?" do
    let(:text) { FactoryBot.create(:social_announcement_text, social_announcement: announcement, body: "v1") }

    it "is false without a review and true after reviewing the current body" do
      expect(text).not_to be_approved
      SocialAnnouncementTextReview.create_for!(text, reviewer: reviewer)
      expect(text).to be_approved
    end

    it "becomes unapproved when the body changes" do
      SocialAnnouncementTextReview.create_for!(text, reviewer: reviewer)
      text.update!(body: "v2")
      expect(text).not_to be_approved
      expect(text.reviews.count).to eq(1)
    end

    it "requires re-review even when reverting to a previously reviewed body" do
      SocialAnnouncementTextReview.create_for!(text, reviewer: reviewer)
      travel_to(1.minute.from_now) { text.update!(body: "v2") }
      travel_to(2.minutes.from_now) { text.update!(body: "v1") }
      expect(text).not_to be_approved

      travel_to(3.minutes.from_now) { SocialAnnouncementTextReview.create_for!(text, reviewer: reviewer) }
      expect(text.reload).to be_approved
      expect(text.reviews.count).to eq(1)
    end

    it "becomes unapproved when media changes" do
      SocialAnnouncementTextReview.create_for!(text, reviewer: reviewer)
      FactoryBot.create(:social_announcement_media, social_announcement: announcement)
      expect(text.reload).not_to be_approved
    end

    it "becomes unapproved when media alt text changes" do
      medium = FactoryBot.create(:social_announcement_media, social_announcement: announcement, alt_text_ja: "a")
      SocialAnnouncementTextReview.create_for!(text, reviewer: reviewer)
      medium.update!(alt_text_ja: "b")
      expect(text.reload).not_to be_approved
    end
  end

  describe "destroy" do
    let(:text) { FactoryBot.create(:social_announcement_text, social_announcement: announcement) }
    let(:target) { FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement) }

    it "is rejected when it has posts" do
      FactoryBot.create(:social_announcement_post, social_announcement_text: text, social_announcement_target_platform: target)
      expect(text.destroy).to be false
      expect(text.errors[:base].first).to match(/already has posts/)
    end

    it "cascades from the announcement" do
      FactoryBot.create(:social_announcement_post, social_announcement_text: text, social_announcement_target_platform: target)
      expect { announcement.destroy! }.to change { SocialAnnouncementPost.count }.by(-1)
    end
  end

  it "allows updating body after a post succeeded" do
    text = FactoryBot.create(:social_announcement_text, social_announcement: announcement)
    target = FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement)
    FactoryBot.create(:social_announcement_post, :succeeded, social_announcement_text: text, social_announcement_target_platform: target)
    expect(text.update(body: "new")).to be true
  end
end
