require 'rails_helper'

RSpec.describe "Talks", type: :request do
  let(:event) { FactoryBot.create(:event) }
  let(:talk) { FactoryBot.create(:talk, event: event) }

  before { prepare_current_event(event) }

  describe "GET /:event_slug/talks" do
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
