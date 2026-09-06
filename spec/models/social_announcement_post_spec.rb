require "rails_helper"

RSpec.describe SocialAnnouncementPost, type: :model do
  it "rejects text and target platform from different announcements" do
    text = FactoryBot.create(:social_announcement_text)
    other_target = FactoryBot.create(:social_announcement_target_platform)
    post = described_class.new(social_announcement_text: text, social_announcement_target_platform: other_target)
    expect(post).not_to be_valid
    expect(post.errors[:base].first).to match(/same announcement/)
  end

  it "requires remote fields when succeeded" do
    post = FactoryBot.build(:social_announcement_post, status: "succeeded")
    expect(post).not_to be_valid
    expect(post.errors.attribute_names).to include(:remote_id, :remote_url, :posted_body, :posted_media_digest, :posted_at)
  end

  it "rejects a non-http remote_url when succeeded" do
    post = FactoryBot.build(:social_announcement_post, :succeeded, remote_url: "javascript:alert(1)")
    expect(post).not_to be_valid
    expect(post.errors.attribute_names).to include(:remote_url)
    expect(FactoryBot.build(:social_announcement_post, :succeeded, remote_url: "https://example.test/p/1")).to be_valid
  end

  it "requires last_error when failed" do
    post = FactoryBot.build(:social_announcement_post, status: "failed")
    expect(post).not_to be_valid
    expect(post.errors.attribute_names).to include(:last_error)
  end

  it "is unique per text and target" do
    post = FactoryBot.create(:social_announcement_post)
    dup = described_class.new(social_announcement_text: post.social_announcement_text, social_announcement_target_platform: post.social_announcement_target_platform)
    expect { dup.save! }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
