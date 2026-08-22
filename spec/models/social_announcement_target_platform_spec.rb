require "rails_helper"

RSpec.describe SocialAnnouncementTargetPlatform, type: :model do
  let(:announcement) { FactoryBot.create(:social_announcement) }

  it "validates platform inclusion and uniqueness" do
    expect(FactoryBot.build(:social_announcement_target_platform, social_announcement: announcement, platform: "threads")).not_to be_valid
    FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "x")
    expect(FactoryBot.build(:social_announcement_target_platform, social_announcement: announcement, platform: "x")).not_to be_valid
  end

  it "cannot be destroyed standalone when it has posts" do
    target = FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement)
    text = FactoryBot.create(:social_announcement_text, social_announcement: announcement)
    FactoryBot.create(:social_announcement_post, social_announcement_text: text, social_announcement_target_platform: target)
    expect(target.destroy).to be false
  end
end
