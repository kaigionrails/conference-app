require "rails_helper"

RSpec.describe SocialOauthToken, type: :model do
  it "encrypts tokens at rest" do
    token = FactoryBot.create(:social_oauth_token, access_token: "plain-access")
    raw = described_class.connection.select_value("SELECT access_token FROM social_oauth_tokens WHERE id = #{token.id}")
    expect(raw).not_to include("plain-access")
    expect(token.reload.access_token).to eq("plain-access")
  end

  it "is unique per platform" do
    FactoryBot.create(:social_oauth_token)
    expect(FactoryBot.build(:social_oauth_token)).not_to be_valid
  end

  describe "#expires_soon?" do
    it "is true within the skew" do
      expect(FactoryBot.build(:social_oauth_token, access_token_expires_at: 4.minutes.from_now)).to be_expires_soon
      expect(FactoryBot.build(:social_oauth_token, access_token_expires_at: 10.minutes.from_now)).not_to be_expires_soon
    end
  end
end
