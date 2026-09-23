require "rails_helper"

RSpec.describe SponsorVisitToken do
  describe ".generate" do
    it "generates a stable opaque token for an event and sponsor" do
      token = described_class.generate(event_slug: "2026", sponsor_key: "sponsor.example")

      expect(token).to eq(described_class.generate(event_slug: "2026", sponsor_key: "sponsor.example"))
      expect(token).not_to include("2026", "sponsor.example")
      expect(token.length).to eq(43)
    end

    it "generates different tokens for different events" do
      token_2025 = described_class.generate(event_slug: "2025", sponsor_key: "sponsor.example")
      token_2026 = described_class.generate(event_slug: "2026", sponsor_key: "sponsor.example")

      expect(token_2025).not_to eq(token_2026)
    end

    it "generates different tokens when the secret changes" do
      token = described_class.generate(event_slug: "2026", sponsor_key: "sponsor.example")
      allow(Rails.configuration.x).to receive(:sponsor_visit_token_secret).and_return("another-secret")

      expect(described_class.generate(event_slug: "2026", sponsor_key: "sponsor.example")).not_to eq(token)
    end
  end

  describe ".stamp_url" do
    it "uses the configured origin, port and path prefix" do
      allow(Rails.configuration).to receive(:application_url).and_return("https://conference.example:8443/app/")
      token = described_class.generate(event_slug: "2026", sponsor_key: "sponsor.example")

      expect(described_class.stamp_url(event_slug: "2026", sponsor_key: "sponsor.example")).to eq(
        "https://conference.example:8443/app/sponsor_passports/2026/stamps/new?code=#{token}"
      )
    end
  end

  describe ".find_sponsor" do
    let(:sponsors) do
      [
        {key: "first-sponsor.example", name: "First Sponsor", plan: "gold"},
        {key: "second-sponsor.example", name: "Second Sponsor", plan: "silver"}
      ]
    end

    it "finds the sponsor matching the token" do
      token = described_class.generate(event_slug: "2026", sponsor_key: "first-sponsor.example")

      expect(described_class.find_sponsor(event_slug: "2026", sponsors: sponsors, token: token)).to eq(sponsors.first)
    end

    it "does not accept an invalid or differently scoped token" do
      token = described_class.generate(event_slug: "2025", sponsor_key: "first-sponsor.example")

      expect(described_class.find_sponsor(event_slug: "2026", sponsors: sponsors, token: token)).to be_nil
      expect(described_class.find_sponsor(event_slug: "2026", sponsors: sponsors, token: "invalid")).to be_nil
    end
  end
end
