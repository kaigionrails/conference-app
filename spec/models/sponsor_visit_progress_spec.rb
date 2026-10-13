require "rails_helper"

RSpec.describe SponsorVisitProgress do
  let(:visited_count) { 0 }
  let(:total_count) { 22 }

  subject(:progress) { described_class.new(visited_count:, total_count:) }

  context "with seven visited booths" do
    let(:visited_count) { 7 }

    it "reports the current milestone and badge thresholds" do
      expect(progress.current_milestone).to eq(count: 5, key: :hello_sponsors)
      expect(progress.milestones).to eq([
        {count: 5, key: :hello_sponsors},
        {count: 12, key: :halfway},
        {count: 22, key: :complete}
      ])
      expect(progress).not_to be_completed
    end
  end

  it "has no earned milestone for a new participant" do
    expect(progress.current_milestone).to be_nil
  end

  context "with a single booth" do
    let(:total_count) { 1 }

    it "has only the completion milestone" do
      expect(progress.milestones).to eq([{count: 1, key: :complete}])
      expect(progress.percentage).to eq(0)
      expect(progress.percentage(1)).to eq(100)
    end
  end

  context "without booths" do
    let(:total_count) { 0 }

    it "does not report completion or divide by zero" do
      expect(progress.percentage).to eq(0)
      expect(progress).not_to be_completed
      expect(progress.current_milestone).to be_nil
    end
  end

  context "with every booth visited" do
    let(:visited_count) { 22 }

    it "reports completion using the supplied sponsor total" do
      expect(progress.current_milestone).to eq(count: 22, key: :complete)
      expect(progress).to be_completed
    end
  end
end
