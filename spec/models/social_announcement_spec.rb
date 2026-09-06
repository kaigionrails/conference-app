require "rails_helper"

RSpec.describe SocialAnnouncement, type: :model do
  let(:reviewer) { FactoryBot.create(:user, role: "organizer") }
  let(:announcement) { FactoryBot.create(:social_announcement, :with_texts) }
  let(:texts) { announcement.texts.order(:locale).to_a }

  def approve_all
    announcement.texts.each { |t| SocialAnnouncementTextReview.create_for!(t, reviewer: reviewer) }
  end

  describe "#dispatch_all_posts!" do
    let!(:mastodon) { FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "mastodon") }
    let!(:bluesky) { FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "bluesky") }

    it "raises unless fully approved" do
      expect { announcement.dispatch_all_posts! }.to raise_error(Social::PostError, /not fully approved/)
    end

    it "raises when X is targeted but not connected" do
      approve_all
      FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "x")
      expect { announcement.reload.dispatch_all_posts! }.to raise_error(Social::PostError, /X is not connected/)
    end

    it "creates pending posts and enqueues a job per combination" do
      approve_all
      expect { announcement.dispatch_all_posts! }
        .to have_enqueued_job(SocialAnnouncementPostJob).exactly(4).times
      expect(SocialAnnouncementPost.pending.count).to eq(4)
    end

    it "skips succeeded posts and re-enqueues failed ones" do
      approve_all
      FactoryBot.create(:social_announcement_post, :succeeded, social_announcement_text: texts.first, social_announcement_target_platform: mastodon)
      failed = FactoryBot.create(:social_announcement_post, social_announcement_text: texts.first, social_announcement_target_platform: bluesky, status: "failed", last_error: "boom", last_error_at: Time.current)

      expect { announcement.dispatch_all_posts! }
        .to have_enqueued_job(SocialAnnouncementPostJob).exactly(3).times
      expect(failed.reload).to be_pending
      expect(failed.last_error).to be_nil
      expect(SocialAnnouncementPost.succeeded.count).to eq(1)
    end
  end

  describe "#dispatch_all_posts! with posts in flight" do
    let!(:mastodon) { FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "mastodon") }

    it "skips a post that another job is currently posting, but re-dispatches a stale one" do
      approve_all
      in_flight = FactoryBot.create(:social_announcement_post, social_announcement_text: texts.first, social_announcement_target_platform: mastodon, status: "posting")
      stale = FactoryBot.create(:social_announcement_post, social_announcement_text: texts.last, social_announcement_target_platform: mastodon, status: "posting")
      stale.update_columns(updated_at: (SocialAnnouncementPost::POSTING_STALE_AFTER + 1.minute).ago)

      expect { announcement.dispatch_all_posts! }.to have_enqueued_job(SocialAnnouncementPostJob).exactly(1).times
      expect(in_flight.reload).to be_posting
      expect(stale.reload).to be_pending
    end
  end

  describe "#sync_published_at!" do
    let!(:mastodon) { FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "mastodon") }

    it "sets published_at when all posts succeeded and clears it when expected count grows" do
      t1 = Time.zone.parse("2026-08-22 10:00:00")
      t2 = Time.zone.parse("2026-08-22 11:00:00")
      FactoryBot.create(:social_announcement_post, :succeeded, social_announcement_text: texts[0], social_announcement_target_platform: mastodon, posted_at: t1)
      announcement.sync_published_at!
      expect(announcement.published_at).to be_nil

      FactoryBot.create(:social_announcement_post, :succeeded, social_announcement_text: texts[1], social_announcement_target_platform: mastodon, posted_at: t2)
      announcement.sync_published_at!
      expect(announcement.published_at).to eq(t2)

      FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "bluesky")
      expect(announcement.reload.published_at).to be_nil
    end
  end

  describe "#current_media_digest" do
    it "is stable for an empty set" do
      expect(announcement.current_media_digest).to eq(Digest::SHA256.hexdigest(""))
    end
  end
end
