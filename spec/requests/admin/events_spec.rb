require "rails_helper"

RSpec.describe "Admin::Events", type: :request do
  let(:admin) { FactoryBot.create(:user, role: "organizer") }
  let!(:event) { FactoryBot.create(:event, name: "Kaigi on Rails 2000", start_date: Time.zone.parse("2000-01-01 00:00:00 +0900")) }

  before { sign_in(admin) }

  describe "GET /admin/events" do
    it "should access correctly" do
      get admin_events_path
      expect(response).to have_http_status(200)
      expect(response.body).to include("Kaigi on Rails 2000")
    end
  end

  describe "GET /admin/events/:id" do
    it "should access correctly" do
      get admin_event_path(event)
      expect(response).to have_http_status(200)
      expect(response.body).to include("Kaigi on Rails 2000")
      expect(response.body).to include("2000-01-01")
    end
  end

  describe "POST /admin/events" do
    context "with valid params" do
      it "should create new event correctly" do
        event_param = {
          name: "Kaigi on Rails 2001",
          slug: "2001",
          start_date_jst: "2001-01-01 00:00:00",
          end_date_jst: "2001-01-02 23:59:59"
        }
        post admin_events_path, params: {event: event_param}
        expect(response).to have_http_status(302)
        event = Event.find_by!(slug: "2001")
        expect(response).to redirect_to(admin_event_path(event))
        expect(event.name).to eq("Kaigi on Rails 2001")
        expect(event.start_date.in_time_zone("Tokyo")).to eq(Time.zone.parse("2001-01-01 00:00:00 +0900"))
      end
    end

    context "with invalid params" do
      it "should failed to create new event" do
        event_param = {
          name: "Kaigi on Rails 2001",
          start_date_jst: "2001-01-01 00:00:00",
          end_date_jst: "2001-01-02 23:59:59"
        }
        post admin_events_path, params: {event: event_param}
        expect(Event.find_by(slug: "2001")).to be_nil
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Create failed")

        get admin_events_path
        expect(response.body).not_to include("Create failed")
      end
    end
  end

  describe "PATCH /admin/events/:id" do
    context "with valid params" do
      it "should update correctly" do
        event_param = {
          name: "Kaigi on Rails 2001",
          slug: "2001",
          start_date_jst: "2001-01-01 00:00:00",
          end_date_jst: "2001-01-02 23:59:59"
        }
        patch admin_event_path(event), params: {event: event_param}
        event.reload
        expect(event.name).to eq("Kaigi on Rails 2001")
        expect(event.start_date.in_time_zone("Tokyo")).to eq(Time.zone.parse("2001-01-01 00:00:00 +0900"))

        follow_redirect!
        expect(response.body).to include(%(id="toasts"))
        expect(response.body).to include("Update succeeded")
      end
    end

    context "with invalid params" do
      let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: event) }

      it "should failed to update event" do
        event_param = {
          name: "Kaigi on Rails 2001",
          slug: "", # empty slug
          start_date_jst: "2001-01-01 00:00:00",
          end_date_jst: "2001-01-02 23:59:59"
        }
        patch admin_event_path(event), params: {event: event_param}
        event.reload
        expect(event.name).to eq("Kaigi on Rails 2000")
        expect(event.start_date.in_time_zone("Tokyo")).to eq(Time.zone.parse("2000-01-01 00:00:00 +0900"))
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Update failed")
        expect(response.body).to include(admin_ongoing_event_path(ongoing_event))

        get admin_events_path
        expect(response.body).not_to include("Update failed")
      end
    end
  end
end
