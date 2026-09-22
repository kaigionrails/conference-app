require "rails_helper"

RSpec.describe SponsorCatalog do
  let(:catalog) { Class.new(described_class) }
  let(:sponsor_data) do
    [
      {
        key: "ruby-sponsor.example",
        name: "Ruby Sponsor",
        plan: "ruby",
        logo: "ruby-sponsor",
        labels: [{name: "Booth", type: "booth"}, {name: "Community supporter", type: "custom"}]
      },
      {
        key: "gold-sponsor.example",
        name: "Gold Sponsor",
        plan: "gold",
        logo: "gold-sponsor"
      }
    ]
  end

  before do
    allow(YAML).to receive(:safe_load_file).and_return(sponsors: sponsor_data)
  end

  describe "configured catalog data" do
    it "provides valid sponsor attributes without duplicate keys" do
      allow(YAML).to receive(:safe_load_file).and_call_original

      sponsors = catalog.for_year(2026)

      expect(sponsors).not_to be_empty
      expect(sponsors).to all(include(:key, :name, :plan, :logo, :booth))
      expect(sponsors.pluck(:key)).to contain_exactly(*sponsors.pluck(:key).uniq)
      expect(sponsors).to all(satisfy { |sponsor| !sponsor.key?(:url) && !sponsor.key?(:profile) })
    end
  end

  describe ".for_year" do
    subject(:sponsors) { catalog.for_year(2026) }

    it "loads the sponsors for the year" do
      expect(YAML).to receive(:safe_load_file).with(
        Rails.root.join("data/sponsors/2026.yaml"),
        permitted_classes: [Symbol], aliases: false
      ).and_return(sponsors: sponsor_data)

      expect(sponsors.pluck(:key)).to eq(["ruby-sponsor.example", "gold-sponsor.example"])
    end

    it "keeps sponsors without a booth available" do
      expect(sponsors).to include(include(key: "gold-sponsor.example", booth: false))
    end

    it "keeps labels from the sponsor master" do
      sponsor = sponsors.find { |entry| entry[:key] == "ruby-sponsor.example" }

      expect(sponsor[:labels]).to include(name: "Community supporter", type: "custom")
    end
  end

  describe "catalog caching" do
    it "reuses the loaded catalog across lookup methods and year representations" do
      expect(YAML).to receive(:safe_load_file).once.and_return(sponsors: sponsor_data)

      sponsors = catalog.for_year(2026)
      expect(catalog.for_year("2026")).to equal(sponsors)
      expect(catalog.with_booth(2026)).not_to be_empty
    end

    it "keeps each year's catalog separate" do
      [2026, 2027].each do |year|
        expect(YAML).to receive(:safe_load_file).with(
          Rails.root.join("data/sponsors/#{year}.yaml"),
          permitted_classes: [Symbol], aliases: false
        ).once.and_return(sponsors: [{key: "sponsor-#{year}", name: "Sponsor", plan: "gold", logo: "logo"}])
      end

      2.times do
        expect(catalog.for_year(2026).pluck(:key)).to eq(["sponsor-2026"])
        expect(catalog.for_year(2027).pluck(:key)).to eq(["sponsor-2027"])
      end
    end

    it "does not cache failed loads" do
      allow(YAML).to receive(:safe_load_file).and_return(sponsors: [{key: "invalid"}])
      expect { catalog.for_year(2026) }.to raise_error(KeyError, /Missing sponsor attributes/)

      allow(YAML).to receive(:safe_load_file).and_return(sponsors: sponsor_data)
      expect(catalog.for_year(2026).size).to eq(2)
    end
  end

  describe ".logo_url" do
    it "builds the official site URL from the year and logo identifier" do
      allow(Rails.configuration.x).to receive(:official_site_url).and_return("https://official.example")
      sponsor = {logo: "example-sponsor"}

      expect(catalog.logo_url(2026, sponsor)).to eq(
        "https://official.example/2026/images/sponsors/example-sponsor.png"
      )
    end
  end

  describe ".with_booth" do
    subject(:sponsors) { catalog.with_booth(2026) }

    it "returns only sponsors with a booth" do
      expect(sponsors.size).to eq(1)
      expect(sponsors).to all(include(booth: true))
      expect(sponsors.pluck(:key)).to include("ruby-sponsor.example")
      expect(sponsors.pluck(:key)).not_to include("gold-sponsor.example")
    end
  end
end
