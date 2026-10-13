require "rails_helper"

RSpec.describe SponsorStampCollector do
  let(:user) { FactoryBot.create(:user) }
  let(:event) { FactoryBot.create(:event) }
  let(:other_event) { FactoryBot.create(:event) }
  let(:sponsors) { [{key: "first"}, {key: "last"}] }
  let(:sponsor_key) { "first" }
  let(:collector) { described_class.new(user:, event:) }

  subject(:result) { collector.collect!(sponsor_key:) }

  before { allow(SponsorCatalog).to receive(:with_booth).and_return(sponsors) }

  it "records an intermediate visit without awarding completion" do
    expect(result.newly_visited).to be(true)
    expect(result.newly_completed).to be(false)
  end

  context "when collecting the final booth" do
    let(:sponsor_key) { "last" }

    before { collector.collect!(sponsor_key: "first") }

    it "awards completion with the last visit's timestamp" do
      expect(result.newly_completed).to be(true)
      expect(user.sponsor_stamp_rally_completions.sole.completed_at).to eq(result.visit.created_at)
    end

    context "when the stamp has already been collected" do
      let(:completion) { user.sponsor_stamp_rally_completions.sole }

      before do
        collector.collect!(sponsor_key: "last")
      end

      it "keeps the visit and completion unchanged on a repeat scan" do
        expect { result }.not_to change { completion.reload.completed_at }
        expect(result.newly_visited).to be(false)
        expect(result.newly_completed).to be(false)
        expect(user.sponsor_visits.count).to eq(2)
        expect(user.sponsor_stamp_rally_completions.count).to eq(1)
      end
    end

    context "when saving the completion fails" do
      before { allow(SponsorStampRallyCompletion).to receive(:create!).and_raise(ActiveRecord::RecordInvalid) }

      it "rolls back the visit" do
        expect { result }.to raise_error(ActiveRecord::RecordInvalid)
        expect(user.sponsor_visits.pluck(:sponsor_key)).to eq(["first"])
        expect(user.sponsor_stamp_rally_completions).to be_empty
      end
    end
  end

  context "with a key outside the catalog" do
    let(:sponsor_key) { "unknown" }

    it "rejects the key without saving" do
      expect { result }.to raise_error(ActiveRecord::RecordNotFound)
      expect(user.sponsor_visits).to be_empty
      expect(user.sponsor_stamp_rally_completions).to be_empty
    end
  end

  context "with unrelated visits" do
    before do
      FactoryBot.create(:sponsor_visit, user:, event:, sponsor_key: "unknown")
      FactoryBot.create(:sponsor_visit, user:, event: other_event, sponsor_key: "last")
    end

    it "ignores unrelated keys and other events" do
      expect(result.newly_completed).to be(false)
      expect(user.sponsor_stamp_rally_completions).to be_empty
    end
  end

  context "without booths" do
    let(:sponsors) { [] }

    it "does not award completion" do
      expect(user.with_lock { SponsorStampRallyCompletion.award_if_eligible!(user:, event:) }).to be_nil
    end
  end

  context "with a completed event" do
    let(:other_collector) { described_class.new(user:, event: other_event) }

    before do
      collector.collect!(sponsor_key: "first")
      collector.collect!(sponsor_key: "last")
    end

    it "awards a separate completion for another event" do
      other_collector.collect!(sponsor_key: "first")
      other_collector.collect!(sponsor_key: "last")
      expect(user.sponsor_stamp_rally_completions.pluck(:event_id)).to contain_exactly(event.id, other_event.id)
    end
  end
end
