require "rails_helper"

RSpec.describe "Talks", type: :request do
  let(:event) { FactoryBot.create(:event, :make_ongoing) }
  let(:talk) { FactoryBot.create(:talk, event: event) }

  describe "GET /:event_slug/talks" do
    it "shows the 2026 halls with matching badge classes in schedule order" do
      start_at = Time.zone.now.beginning_of_hour
      FactoryBot.create(:talk, event: event, track: "Lime Hall", start_at: start_at)
      FactoryBot.create(:talk, event: event, track: "Magenta Hall", start_at: start_at)

      get event_talks_path(event_slug: event.slug)

      badges = Nokogiri::HTML(response.body).css(".pill")
      expect(badges.map(&:text)).to eq ["Magenta Hall", "Lime Hall"]
      expect(badges.map { |badge| badge["class"].split.last }).to eq ["pill__magenta-hall", "pill__lime-hall"]
    end

    context "not logged in" do
      it "should able to see talks without logged-in" do
        get event_talks_path(event_slug: talk.event.slug)
        expect(response).to have_http_status(200)
      end
    end

    context "logged in" do
      let(:user) { FactoryBot.create(:user) }

      before { sign_in(user) }
      it "should able to see talks" do
        get event_talks_path(event_slug: talk.event.slug)
        expect(response).to have_http_status(200)
      end
    end
  end

  describe "GET /:event/slug/talks/:id" do
    context "not logged in" do
      it "should able to see talk without logged-in" do
        get event_talk_path(event_slug: talk.event.slug, id: talk.id)
        expect(response).to have_http_status(200)
      end
    end

    context "logged in" do
      let(:user) { FactoryBot.create(:user) }

      before { sign_in(user) }
      it "should able to see talk" do
        get event_talk_path(event_slug: talk.event.slug, id: talk.id)
        expect(response).to have_http_status(200)
      end
    end
  end
end
