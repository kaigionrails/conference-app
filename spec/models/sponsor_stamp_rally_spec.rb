require "rails_helper"

RSpec.describe SponsorStampRally do
  subject(:stamp_rally) { described_class.new(event:) }

  let(:event) { FactoryBot.create(:event) }
  let(:booth_sponsor) { {key: "booth.example", name: "Booth Sponsor", plan: "gold", logo: "booth", booth: true} }
  let(:unvisited_sponsor) { booth_sponsor.merge(key: "unvisited.example", name: "Unvisited Sponsor") }

  before do
    allow(SponsorCatalog).to receive(:available_for_year?).with(event.slug).and_return(true)
    allow(SponsorCatalog).to receive(:with_booth).with(event.slug).and_return([booth_sponsor, unvisited_sponsor])
  end

  it "counts stamps across events, within the selected event and per sponsor, including organizers" do
    organizer = FactoryBot.create(:user, role: :organizer)
    FactoryBot.create(:sponsor_visit, user: organizer, event:, sponsor_key: booth_sponsor[:key])
    FactoryBot.create(:sponsor_visit, event:, sponsor_key: booth_sponsor[:key])
    FactoryBot.create(:sponsor_visit, sponsor_key: booth_sponsor[:key])

    expect(stamp_rally.total_stamp_count).to eq(3)
    expect(stamp_rally.event_stamp_count).to eq(2)
    expect(stamp_rally.stamp_count_for(booth_sponsor[:key])).to eq(2)
    expect(stamp_rally.stamp_count_for(unvisited_sponsor[:key])).to eq(0)
  end

  it "keeps unvisited booth sponsors available with zero counts" do
    expect(stamp_rally.total_stamp_count).to eq(0)
    expect(stamp_rally.event_stamp_count).to eq(0)
    expect(stamp_rally.stamp_count_for(booth_sponsor[:key])).to eq(0)
    expect(stamp_rally.sponsors.pluck(:key)).to contain_exactly(booth_sponsor[:key], unvisited_sponsor[:key])
  end

  it "builds stamp URLs for the selected event" do
    sponsor = stamp_rally.qr_sponsors.find { |entry| entry[:key] == booth_sponsor[:key] }

    expect(sponsor).to include(stamp_url: SponsorVisitToken.stamp_url(event_slug: event.slug, sponsor_key: booth_sponsor[:key]))
  end

  it "retains removed sponsors and their counts without offering QR distribution" do
    FactoryBot.create(:sponsor_visit, event:, sponsor_key: "removed.example")

    expect(stamp_rally.sponsors).to include(include(key: "removed.example", name: "removed.example", stamp_url: nil))
    expect(stamp_rally.stamp_count_for("removed.example")).to eq(1)
    expect(stamp_rally.event_stamp_count).to eq(1)
    expect(stamp_rally.qr_sponsors.pluck(:key)).not_to include("removed.example")
  end

  context "without catalog data" do
    before { allow(SponsorCatalog).to receive(:available_for_year?).with(event.slug).and_return(false) }

    it "keeps recorded sponsor keys and counts available" do
      FactoryBot.create(:sponsor_visit, event:, sponsor_key: "archived.example")

      expect(stamp_rally.sponsors).to contain_exactly(include(key: "archived.example", name: "archived.example", stamp_url: nil))
      expect(stamp_rally.stamp_count_for("archived.example")).to eq(1)
      expect(stamp_rally.event_stamp_count).to eq(1)
      expect(stamp_rally.qr_sponsors).to be_empty
    end

    it "handles events without any recorded stamps" do
      expect(stamp_rally.sponsors).to be_empty
      expect(stamp_rally.qr_sponsors).to be_empty
      expect(stamp_rally.event_stamp_count).to eq(0)
    end
  end

  it "provides an unsaved template for the selected event when none exists" do
    expect(stamp_rally.template).to be_new_record
    expect(stamp_rally.template.event).to eq(event)
  end

  it "keeps the existing template attached to the event" do
    template = FactoryBot.create(:sponsor_booth_qr_card_template, event:)

    expect(stamp_rally.template).to eq(template)
    expect(event.reload.sponsor_booth_qr_card_template).to eq(template)
  end
end
