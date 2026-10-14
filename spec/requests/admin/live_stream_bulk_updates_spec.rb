require "rails_helper"

RSpec.describe "Admin::LiveStreamBulkUpdates", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing) }
  let!(:magenta) { FactoryBot.create(:cloudflare_stream_live_stream, event: event, uid: "magentauid", name: "kaigionrails-2026-magenta-ja") }
  let!(:lime) { FactoryBot.create(:cloudflare_stream_live_stream, event: event, uid: "limeuid", name: "kaigionrails-2026-lime-ja") }

  def live_input_url(uid)
    "https://api.cloudflare.com/client/v4/accounts/testtesttesttest/stream/live_inputs/#{uid}"
  end

  def stub_live_input(uid, name)
    stub_request(:get, live_input_url(uid)).to_return(
      status: 200,
      body: JSON.dump(success: true, errors: [], result: {uid: uid, meta: {name: name}, playback: {hls: "https://example.com/#{uid}.m3u8"}}),
      headers: {"Content-Type": "application/json"}
    )
    stub_request(:get, "#{live_input_url(uid)}/videos").to_return(
      status: 200,
      body: JSON.dump(success: true, errors: [], result: []),
      headers: {"Content-Type": "application/json"}
    )
  end

  describe "POST /admin/live_stream_bulk_update" do
    context "as an organizer" do
      before { sign_in(FactoryBot.create(:user, role: "organizer")) }

      it "updates every live stream from the API" do
        stub_live_input("magentauid", "kaigionrails-2026-magenta-ja updated")
        stub_live_input("limeuid", "kaigionrails-2026-lime-ja updated")

        post admin_live_stream_bulk_update_path

        expect(response).to redirect_to(admin_live_streams_path)
        expect(flash[:success]).to eq("Updated all live streams")
        expect(magenta.reload.name).to eq("kaigionrails-2026-magenta-ja updated")
        expect(magenta.url).to eq("https://example.com/magentauid.m3u8")
        expect(lime.reload.name).to eq("kaigionrails-2026-lime-ja updated")
        expect(lime.url).to eq("https://example.com/limeuid.m3u8")
      end

      it "keeps a live stream whose live input the API fails to return" do
        stub_request(:get, live_input_url("magentauid")).to_return(
          status: 200,
          body: JSON.dump(success: false, errors: [{code: 1000}]),
          headers: {"Content-Type": "application/json"}
        )
        stub_live_input("limeuid", "kaigionrails-2026-lime-ja updated")

        post admin_live_stream_bulk_update_path

        expect(response).to redirect_to(admin_live_streams_path)
        expect(flash[:alert]).to eq("Failed to update: kaigionrails-2026-magenta-ja")
        expect(CloudflareStreamLiveStream.exists?(magenta.id)).to eq(true)
        expect(lime.reload.name).to eq("kaigionrails-2026-lime-ja updated")
      end

      it "goes on with the others when the API times out" do
        stub_request(:get, live_input_url("magentauid")).to_timeout
        stub_live_input("limeuid", "kaigionrails-2026-lime-ja updated")

        post admin_live_stream_bulk_update_path

        expect(response).to redirect_to(admin_live_streams_path)
        expect(flash[:alert]).to eq("Failed to update: kaigionrails-2026-magenta-ja")
        expect(magenta.reload.name).to eq("kaigionrails-2026-magenta-ja")
        expect(lime.reload.name).to eq("kaigionrails-2026-lime-ja updated")
      end
    end

    context "as a participant" do
      before { sign_in(FactoryBot.create(:user)) }

      it "redirects to the root without calling the API" do
        post admin_live_stream_bulk_update_path

        expect(response).to redirect_to(root_path)
        expect(a_request(:get, %r{api.cloudflare.com})).not_to have_been_made
      end
    end

    context "when not logged in" do
      it "redirects to the root without calling the API" do
        post admin_live_stream_bulk_update_path

        expect(response).to redirect_to(root_path)
        expect(a_request(:get, %r{api.cloudflare.com})).not_to have_been_made
      end
    end
  end
end
