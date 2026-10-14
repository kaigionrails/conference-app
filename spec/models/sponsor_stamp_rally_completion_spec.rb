require "rails_helper"

RSpec.describe SponsorStampRallyCompletion do
  let(:user) { FactoryBot.create(:user) }
  let(:event) { FactoryBot.create(:event) }
  let(:completed_at) { Time.current }

  subject(:completion) { FactoryBot.build(:sponsor_stamp_rally_completion, user:, event:, completed_at:) }

  describe ".newest_event_first" do
    let(:older_event) { FactoryBot.create(:event, start_date: Date.new(2024, 10, 1)) }
    let(:newer_event) { FactoryBot.create(:event, start_date: Date.new(2025, 10, 1)) }
    let(:tied_event) { FactoryBot.create(:event, start_date: newer_event.start_date) }
    let!(:older_completion) { FactoryBot.create(:sponsor_stamp_rally_completion, user:, event: older_event, completed_at: Time.zone.local(2026, 10, 1)) }
    let!(:newer_completion) { FactoryBot.create(:sponsor_stamp_rally_completion, user:, event: newer_event, completed_at: Time.zone.local(2025, 10, 1)) }
    let!(:tied_completion) { FactoryBot.create(:sponsor_stamp_rally_completion, user:, event: tied_event) }
    let!(:other_completion) { FactoryBot.create(:sponsor_stamp_rally_completion, event: newer_event) }

    subject(:completions) { user.sponsor_stamp_rally_completions.newest_event_first }

    it "orders the user's completions by event start date and then event ID descending" do
      expect(completions).to eq([tied_completion, newer_completion, older_completion])
    end
  end

  context "without a completion timestamp" do
    let(:completed_at) { nil }

    it "is invalid" do
      expect(completion).not_to be_valid
    end
  end

  context "with an existing completion" do
    let!(:existing_completion) { FactoryBot.create(:sponsor_stamp_rally_completion, user:, event:) }
    let(:other_event) { FactoryBot.create(:event) }
    let(:duplicate_attributes) { existing_completion.attributes.except("id") }

    it "allows only one completion per user and event" do
      expect(completion).not_to be_valid
    end

    context "for another event" do
      subject(:completion) { FactoryBot.build(:sponsor_stamp_rally_completion, user:, event: other_event) }

      it "is valid" do
        expect(completion).to be_valid
      end
    end

    it "enforces uniqueness in the database" do
      expect {
        described_class.transaction(requires_new: true) do
          described_class.insert_all!([duplicate_attributes])
        end
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "removes completions when the user is deleted" do
      user.destroy!
      expect(described_class.exists?(existing_completion.id)).to be(false)
    end

    it "removes completions when the event is deleted" do
      event.destroy!
      expect(described_class.exists?(existing_completion.id)).to be(false)
    end
  end
end
