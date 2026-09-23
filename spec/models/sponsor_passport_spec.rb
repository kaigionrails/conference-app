require "rails_helper"

RSpec.describe SponsorPassport do
  let(:event) { FactoryBot.create(:event, slug: "2026") }
  let(:user) { FactoryBot.create(:user) }
  let(:sponsors) do
    [
      {key: "first.example", name: "First Sponsor", plan: "ruby", booth: true},
      {key: "second.example", name: "Second Sponsor", plan: "gold", booth: true}
    ]
  end

  subject(:passport) { described_class.new(event:, user:) }

  before do
    allow(SponsorCatalog).to receive(:with_booth).with("2026").and_return(sponsors)
  end

  it "represents the user's event-specific passport" do
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "second.example")

    expect(passport.event).to eq(event)
    expect(passport.sponsors).to eq(sponsors)
    expect(passport.visited?("second.example")).to be(true)
    expect(passport.visited?("first.example")).to be(false)
    expect(passport.stamp_number_for("second.example")).to eq(1)
    expect { passport.stamp_number_for("first.example") }.to raise_error(KeyError)
    expect(passport.progress.visited_count).to eq(1)
    expect(passport.progress.total_count).to eq(2)
    expect(passport.progress.current_milestone).to eq(count: 1, key: :hello_sponsors)
  end

  it "numbers only passport sponsors in visit order, breaking ties by ID" do
    time = Time.current
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "not-in-passport.example", created_at: time)
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "second.example", created_at: time)
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "first.example", created_at: time)

    expect(passport.stamp_number_for("second.example")).to eq(1)
    expect(passport.stamp_number_for("first.example")).to eq(2)
    expect(passport.progress.visited_count).to eq(2)
    expect(passport).not_to be_visited("not-in-passport.example")
    expect(passport.next_sponsors).to be_empty
  end

  it "suggests only unvisited passport sponsors" do
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "first.example")

    expect(passport.next_sponsors).to eq([sponsors.last])
  end

  it "counts stamps collected across the event for passport sponsors" do
    FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "second.example")
    FactoryBot.create(:sponsor_visit, user: FactoryBot.create(:user), event:, sponsor_key: "first.example")
    FactoryBot.create(:sponsor_visit, user: FactoryBot.create(:user), event:, sponsor_key: "not-in-passport.example")
    other_event = FactoryBot.create(:event, slug: "2025")
    FactoryBot.create(:sponsor_visit, user: FactoryBot.create(:user), event: other_event, sponsor_key: "first.example")

    expect(passport.community_stamp_count).to eq(2)
  end
end
