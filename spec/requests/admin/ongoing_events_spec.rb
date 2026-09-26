require "rails_helper"

RSpec.describe "Admin::OngoingEvents", type: :request do
  let(:admin) { FactoryBot.create(:user, role: "organizer") }
  let!(:past_event) { FactoryBot.create(:event) }
  let!(:will_ongoing_event) { FactoryBot.create(:event) }

  describe "PATCH /admin/ongoing_events/:id" do
    let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: past_event) }

    it "should update correctly" do
      sign_in(admin)
      patch admin_ongoing_event_path(ongoing_event), params: {ongoing_event: {event_id: will_ongoing_event.id}}
      expect(past_event.ongoing?).to be_falsey
      expect(will_ongoing_event.ongoing?).to be_truthy
      expect(OngoingEvent.count).to eq 1
    end

    it "redirects a participant without changing the ongoing event" do
      sign_in(FactoryBot.create(:user, role: "participant"))
      patch admin_ongoing_event_path(ongoing_event), params: {ongoing_event: {event_id: will_ongoing_event.id}}
      expect(response).to redirect_to(root_path)
      expect(past_event.ongoing?).to be_truthy
    end

    it "redirects a logged-out user without changing the ongoing event" do
      patch admin_ongoing_event_path(ongoing_event), params: {ongoing_event: {event_id: will_ongoing_event.id}}
      expect(response).to redirect_to(root_path)
      expect(past_event.ongoing?).to be_truthy
    end
  end

  describe "POST /admin/ongoing_events" do
    it "should create correctly" do
      sign_in(admin)
      post admin_ongoing_events_path, params: {ongoing_event: {event_id: will_ongoing_event.id}}
      expect(past_event.ongoing?).to be_falsey
      expect(will_ongoing_event.ongoing?).to be_truthy
      expect(OngoingEvent.count).to eq 1
    end

    it "redirects a participant without creating an ongoing event" do
      sign_in(FactoryBot.create(:user, role: "participant"))
      post admin_ongoing_events_path, params: {ongoing_event: {event_id: will_ongoing_event.id}}
      expect(response).to redirect_to(root_path)
      expect(OngoingEvent.count).to eq 0
    end

    it "redirects a logged-out user without creating an ongoing event" do
      post admin_ongoing_events_path, params: {ongoing_event: {event_id: will_ongoing_event.id}}
      expect(response).to redirect_to(root_path)
      expect(OngoingEvent.count).to eq 0
    end
  end
end
