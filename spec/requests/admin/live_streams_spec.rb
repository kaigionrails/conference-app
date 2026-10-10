require "rails_helper"

RSpec.describe "Admin::LiveStreams", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing, name: "Kaigi on Rails 2026", slug: "2026") }

  before { sign_in(FactoryBot.create(:user, role: "organizer")) }

  describe "GET /admin/live_streams" do
    it "shows the YOYO Translate URLs of the ongoing event in the form" do
      FactoryBot.create(:yoyo_translate_setting, event: event)

      get admin_live_streams_path

      expect(response).to have_http_status(200)
      expect(response.body).to include("YOYO Translate (Kaigi on Rails 2026)")
      expect(response.body).to include('value="https://example.com/magenta"')
      expect(response.body).to include('value="https://example.com/lime"')
    end

    it "lists the live streams in the order of their ids even after one is updated" do
      first = FactoryBot.create(:cloudflare_stream_live_stream, event: event, name: "kaigionrails-2026-magenta-raw")
      FactoryBot.create(:cloudflare_stream_live_stream, event: event, name: "kaigionrails-2026-lime-raw")
      # Like "Update Live Stream from API", which moves the row to the end of the table in PostgreSQL.
      first.update!(name: "kaigionrails-2026-magenta-raw updated")

      get admin_live_streams_path

      expect(response.body.index("kaigionrails-2026-magenta-raw updated")).to be < response.body.index("kaigionrails-2026-lime-raw")
    end
  end
end
