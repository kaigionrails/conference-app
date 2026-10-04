require "rails_helper"

RSpec.describe SponsorStampCard do
  let(:event) { FactoryBot.create(:event) }
  let(:user) { FactoryBot.create(:user) }
  let(:sponsors) do
    [
      {key: "first.example", name: "First Sponsor", plan: "ruby", booth: true},
      {key: "second.example", name: "Second Sponsor", plan: "gold", booth: true}
    ]
  end

  subject(:stamp_card) { described_class.new(event:, user:) }

  before do
    allow(SponsorCatalog).to receive(:with_booth).with(event.slug).and_return(sponsors)
  end

  it "represents the user's event-specific stamp card" do
    expect(stamp_card.event).to eq(event)
    expect(stamp_card.sponsors).to eq(sponsors)
  end

  context "when the user has visited the second sponsor" do
    before do
      FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "second.example")
    end

    it "identifies visited sponsors" do
      expect(stamp_card.visited?("second.example")).to be(true)
      expect(stamp_card.visited?("first.example")).to be(false)
    end

    it "returns the stamp number for a visited sponsor" do
      expect(stamp_card.stamp_number_for("second.example")).to eq(1)
    end

    it "raises an error for an unvisited sponsor's stamp number" do
      expect { stamp_card.stamp_number_for("first.example") }.to raise_error(KeyError)
    end

    it "reports progress toward visiting all sponsors" do
      expect(stamp_card.progress.visited_count).to eq(1)
      expect(stamp_card.progress.total_count).to eq(2)
      expect(stamp_card.progress.current_milestone).to eq(count: 1, key: :hello_sponsors)
    end
  end

  context "when visits have the same timestamp" do
    let(:visited_at) { Time.current }

    before do
      FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "not-in-stamp-rally.example", created_at: visited_at)
      FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "second.example", created_at: visited_at)
      FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "first.example", created_at: visited_at)
    end

    it "numbers stamp rally sponsors by visit ID" do
      expect(stamp_card.stamp_number_for("second.example")).to eq(1)
      expect(stamp_card.stamp_number_for("first.example")).to eq(2)
    end

    it "counts only stamp rally sponsors as visited" do
      expect(stamp_card.progress.visited_count).to eq(2)
      expect(stamp_card).not_to be_visited("not-in-stamp-rally.example")
    end

    it "has no sponsors left to suggest" do
      expect(stamp_card.next_sponsors).to be_empty
    end
  end

  context "when the user has visited the first sponsor" do
    before do
      FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "first.example")
    end

    it "suggests only unvisited stamp rally sponsors" do
      expect(stamp_card.next_sponsors).to eq([sponsors.last])
    end
  end

  describe "#community_stamp_count" do
    let(:other_event) { FactoryBot.create(:event) }
    let(:other_user) { FactoryBot.create(:user) }

    before do
      FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "second.example")
      FactoryBot.create(:sponsor_visit, user: other_user, event:, sponsor_key: "first.example")
      FactoryBot.create(:sponsor_visit, user: other_user, event:, sponsor_key: "not-in-stamp-rally.example")
      FactoryBot.create(:sponsor_visit, user: other_user, event: other_event, sponsor_key: "first.example")
    end

    it "counts stamps collected across the event for stamp rally sponsors" do
      expect(stamp_card.community_stamp_count).to eq(2)
    end
  end
end
