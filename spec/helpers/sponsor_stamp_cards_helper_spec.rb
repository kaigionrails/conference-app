require "rails_helper"

RSpec.describe SponsorStampCardsHelper, type: :helper do
  let(:event) { FactoryBot.build(:event, slug: year) }
  let(:completion) { FactoryBot.build(:sponsor_stamp_rally_completion, event:) }

  subject(:icon_path) { helper.completion_badge_icon_path(completion) }

  shared_examples "an event-specific icon" do
    it "uses an existing icon from the completion event" do
      expect(icon_path).to eq(expected_path)
      expect(Rails.application.assets.load_path.find(icon_path)).to be_present
    end
  end

  context "for 2023" do
    let(:year) { "2023" }
    let(:expected_path) { "icons/2023/512.png" }

    include_examples "an event-specific icon"
  end

  context "for 2024" do
    let(:year) { "2024" }
    let(:expected_path) { "icons/2024/512.png" }

    include_examples "an event-specific icon"
  end

  context "for 2025" do
    let(:year) { "2025" }
    let(:expected_path) { "icons/2025/512.png" }

    include_examples "an event-specific icon"
  end

  context "for 2026" do
    let(:year) { "2026" }
    let(:expected_path) { "2026/logos/hachiko.svg" }

    include_examples "an event-specific icon"
  end
end
