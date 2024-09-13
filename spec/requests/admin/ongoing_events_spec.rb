require "rails_helper"

RSpec.describe "Admin::OngoingEvents", type: :request do
  let(:admin) { FactoryBot.create(:user, role: "organizer") }
  let!(:past_event) { FactoryBot.create(:event) }
  let!(:will_ongoing_event) { FactoryBot.create(:event) }

  before { sign_in(admin) }

  describe "PATCH /admin/ongoing_events/:id" do
    let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: past_event) }

    it "should update correctly" do
      patch admin_ongoing_event_path(ongoing_event), params: {ongoing_event: {event_id: will_ongoing_event.id}}
      expect(past_event.ongoing?).to be_falsey
      expect(will_ongoing_event.ongoing?).to be_truthy
      expect(OngoingEvent.count).to eq 1
    end
  end

  describe "POST /admin/ongoing_events" do
    it "should create correctly" do
      post admin_ongoing_events_path, params: {ongoing_event: {event_id: will_ongoing_event.id}}
      expect(past_event.ongoing?).to be_falsey
      expect(will_ongoing_event.ongoing?).to be_truthy
      expect(OngoingEvent.count).to eq 1
    end
  end
end
