require 'rails_helper'

RSpec.describe "LiveStreams", type: :request do
  describe "GET /:event_slug/live" do
    context "when event not found" do
      it "returns 404" do
        get "/1999/live"
        expect(response).to have_http_status(404)
      end
    end

    context "when event found" do
      let!(:event) { FactoryBot.create(:event, slug: "2025") }

      it "returns 200" do
        get "/2025/live"
        expect(response).to have_http_status(200)
      end
    end

    # it "works! (now write some real specs)" do
    #   get live_streams_index_path
    #   expect(response).to have_http_status(200)
    # end
  end
end
