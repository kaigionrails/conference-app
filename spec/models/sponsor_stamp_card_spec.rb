require "rails_helper"

RSpec.describe SponsorStampCard do
  let(:event) { FactoryBot.create(:event, slug: "2026") }
  let(:user) { FactoryBot.create(:user) }
  let(:sponsors) do
    [
      {key: "first.example", name: "First Sponsor", plan: "ruby", booth: true},
      {key: "second.example", name: "Second Sponsor", plan: "gold", booth: true}
    ]
  end

  subject(:stamp_card) { described_class.new(event:, user:) }

  before do
    allow(SponsorCatalog).to receive(:with_booth).with("2026").and_return(sponsors)
  end

  it "represents the user's event-specific stamp card" do
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "second.example")

    expect(stamp_card.event).to eq(event)
    expect(stamp_card.sponsors).to eq(sponsors)
    expect(stamp_card.visited?("second.example")).to be(true)
    expect(stamp_card.visited?("first.example")).to be(false)
    expect(stamp_card.stamp_number_for("second.example")).to eq(1)
    expect { stamp_card.stamp_number_for("first.example") }.to raise_error(KeyError)
    expect(stamp_card.progress.visited_count).to eq(1)
    expect(stamp_card.progress.total_count).to eq(2)
    expect(stamp_card.progress.current_milestone).to eq(count: 1, key: :hello_sponsors)
  end

  it "numbers only stamp rally sponsors in visit order, breaking ties by ID" do
    time = Time.current
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "not-in-stamp-rally.example", created_at: time)
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "second.example", created_at: time)
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "first.example", created_at: time)

    expect(stamp_card.stamp_number_for("second.example")).to eq(1)
    expect(stamp_card.stamp_number_for("first.example")).to eq(2)
    expect(stamp_card.progress.visited_count).to eq(2)
    expect(stamp_card).not_to be_visited("not-in-stamp-rally.example")
    expect(stamp_card.next_sponsors).to be_empty
  end

  it "suggests only unvisited stamp rally sponsors" do
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "first.example")

    expect(stamp_card.next_sponsors).to eq([sponsors.last])
  end

  it "counts stamps collected across the event for stamp rally sponsors" do
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "second.example")
    FactoryBot.create(:sponsor_visit, user: FactoryBot.create(:user), event:, sponsor_key: "first.example")
    FactoryBot.create(:sponsor_visit, user: FactoryBot.create(:user), event:, sponsor_key: "not-in-stamp-rally.example")
    other_event = FactoryBot.create(:event, slug: "2025")
    FactoryBot.create(:sponsor_visit, user: FactoryBot.create(:user), event: other_event, sponsor_key: "first.example")

    expect(stamp_card.community_stamp_count).to eq(2)
  end
end
