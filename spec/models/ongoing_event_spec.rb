require "rails_helper"

RSpec.describe OngoingEvent, type: :model do
  describe "no ongoing event" do
    let(:event) { FactoryBot.create(:event) }

    it "creates a new ongoing event" do
      expect(OngoingEvent.count).to eq(0)
      OngoingEvent.create(event: event)
      expect(OngoingEvent.count).to eq(1)
    end
  end

  describe "ongoing event exists" do
    let(:event) { FactoryBot.create(:event) }
    let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: event) }

    context "when creating a new ongoing event" do
      it "doesn't create a new ongoing event" do
        expect(OngoingEvent.count).to eq(1)
        OngoingEvent.create(event: event)
        expect(OngoingEvent.count).to eq(1)
      end
    end

    context "when destroy ongoing event" do
      it "doesn't allow destroy ongoing event" do
        expect(OngoingEvent.count).to eq(1)
        ongoing_event.destroy
        expect(OngoingEvent.count).to eq(1)
      end
    end
  end
end
