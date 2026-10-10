require "rails_helper"

RSpec.describe YoyoTranslateSetting, type: :model do
  let(:event) { FactoryBot.create(:event) }

  describe "URL format" do
    it "accepts https URLs" do
      setting = FactoryBot.build(:yoyo_translate_setting, event: event)

      expect(setting).to be_valid
    end

    it "accepts no URLs" do
      setting = FactoryBot.build(:yoyo_translate_setting, event: event, magenta_hall_url: nil, lime_hall_url: nil)

      expect(setting).to be_valid
    end

    it "rejects URLs that do not start with https://" do
      ["http://example.com", "javascript:alert(1)"].each do |url|
        setting = FactoryBot.build(:yoyo_translate_setting, event: event, magenta_hall_url: url, lime_hall_url: url)

        expect(setting).not_to be_valid
        expect(setting.errors.of_kind?(:magenta_hall_url, :invalid)).to eq(true), "expected #{url} to be invalid"
        expect(setting.errors.of_kind?(:lime_hall_url, :invalid)).to eq(true), "expected #{url} to be invalid"
      end
    end
  end

  describe "normalization" do
    it "turns blank URLs into nil" do
      setting = described_class.new(event: event, magenta_hall_url: "", lime_hall_url: "  ")

      expect(setting.magenta_hall_url).to be_nil
      expect(setting.lime_hall_url).to be_nil
    end

    it "strips surrounding whitespace" do
      setting = described_class.new(event: event, magenta_hall_url: " https://example.com/magenta\n")

      expect(setting.magenta_hall_url).to eq("https://example.com/magenta")
    end
  end

  it "allows only one setting per event" do
    FactoryBot.create(:yoyo_translate_setting, event: event)
    setting = FactoryBot.build(:yoyo_translate_setting, event: event)

    expect(setting).not_to be_valid
    expect(setting.errors.of_kind?(:event_id, :taken)).to eq(true)
  end
end
