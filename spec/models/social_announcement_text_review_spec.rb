require "rails_helper"

RSpec.describe SocialAnnouncementTextReview, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:text) { FactoryBot.create(:social_announcement_text, body: "v1") }
  let(:reviewer) { FactoryBot.create(:user, role: "organizer") }

  it "snapshots the current body and media digests" do
    review = described_class.create_for!(text, reviewer: reviewer)
    expect(review.body_digest).to eq(Digest::SHA256.hexdigest("v1"))
    expect(review.media_digest).to eq(text.social_announcement.current_media_digest)
  end

  it "bumps reviewed_at instead of duplicating when the same reviewer approves the same digests again" do
    first = described_class.create_for!(text, reviewer: reviewer)
    travel_to(1.hour.from_now) do
      expect { described_class.create_for!(text, reviewer: reviewer) }.not_to change { described_class.count }
    end
    expect(first.reload.reviewed_at).to be > first.created_at
  end

  it "allows a different reviewer to approve the same digests" do
    described_class.create_for!(text, reviewer: reviewer)
    expect { described_class.create_for!(text, reviewer: FactoryBot.create(:user)) }.to change { described_class.count }.by(1)
  end

  it "allows the same reviewer to approve a new version" do
    described_class.create_for!(text, reviewer: reviewer)
    text.update!(body: "v2")
    expect { described_class.create_for!(text, reviewer: reviewer) }.to change { described_class.count }.by(1)
    expect(text).to be_approved
  end
end
