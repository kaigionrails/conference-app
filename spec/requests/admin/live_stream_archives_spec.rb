require "rails_helper"

RSpec.describe "Admin::LiveStreamArchives", type: :request do
  let!(:event) { FactoryBot.create(:event, :make_ongoing, name: "Kaigi on Rails 2026", slug: "2026") }
  let(:magenta_uid) { "1bf04fe9c7f78140478d182b90d32896" }
  let(:uid) { "19a1ab8a7d077bc66d5cd422f89cb986" }

  def stream_url
    "https://api.cloudflare.com/client/v4/accounts/testtesttesttest/stream"
  end

  # A recording of a live input in the shape that the Stream API returns.
  def video_attributes(uid:, state: "ready", live_input: "1bf04fe9c7f78140478d182b90d32896", name: "kaigionrails-2026-magenta-raw 17 Oct 26 00:29 UTC", created: "2026-10-17T00:29:12.708196Z")
    {
      uid: uid,
      liveInput: live_input,
      status: {state: state},
      meta: {name: name},
      created: created,
      duration: 31341,
      thumbnail: "https://customer-xxx.cloudflarestream.com/#{uid}/thumbnails/thumbnail.jpg",
      preview: "https://customer-xxx.cloudflarestream.com/#{uid}/watch"
    }
  end

  # Recordings created a minute apart from 2026-10-17 00:00 UTC, the newest first as the API returns them.
  def recordings(count)
    Array.new(count) do |i|
      video_attributes(uid: format("%032x", i + 1), name: "recording #{i + 1}", created: (Time.utc(2026, 10, 17) - i.minutes).iso8601(6))
    end
  end

  def stub_ready_videos(videos, query: {})
    stub_request(:get, stream_url).with(query: {status: "ready", limit: "51"}.merge(query)).to_return(
      status: 200,
      body: JSON.dump(success: true, errors: [], result: videos),
      headers: {"Content-Type": "application/json"}
    )
  end

  def stub_video(uid, body)
    stub_request(:get, "#{stream_url}/#{uid}").to_return(
      status: 200,
      body: JSON.dump(body),
      headers: {"Content-Type": "application/json"}
    )
  end

  def watch_links
    response.body.scan(%r{href="/admin/live_stream_archives/\h{32}"})
  end

  context "as an organizer" do
    before { sign_in(FactoryBot.create(:user, role: "organizer")) }

    describe "GET /admin/live_stream_archives" do
      it "lists the recordings with the live streams registered in the app" do
        FactoryBot.create(
          :cloudflare_stream_live_stream,
          event: event,
          uid: magenta_uid,
          name: "kaigionrails-2026-magenta-raw",
          stream_raw_response: {"result" => {"meta" => {"name" => "kaigionrails-2026-magenta-raw", "hall" => "magenta", "lang" => "ja"}}}
        )
        stub_ready_videos([video_attributes(uid:)])

        get admin_live_stream_archives_path

        expect(response).to have_http_status(200)
        expect(response.body).to include("kaigionrails-2026-magenta-raw 17 Oct 26 00:29 UTC")
        expect(response.body).to include("kaigionrails-2026-magenta-raw (Kaigi on Rails 2026 / hall: magenta / lang: ja)")
        expect(response.body).to include("created: 2026-10-17 09:29 / duration: 8:42:21")
        expect(response.body).to include("https://customer-xxx.cloudflarestream.com/#{uid}/thumbnails/thumbnail.jpg?height=120&amp;fit=clip")
        expect(response.body).to include(%(href="#{admin_live_stream_archive_path(uid)}"))
      end

      it "shows the uid of a live input that is not registered in the app" do
        stub_ready_videos([video_attributes(uid:, live_input: "8dfb35b1f0fd7d1813e97efd689f4a38")])

        get admin_live_stream_archives_path

        expect(response.body).to include("live input: 8dfb35b1f0fd7d1813e97efd689f4a38 (not registered)")
      end

      it "leaves out the uploaded videos, which have no live input" do
        stub_ready_videos([video_attributes(uid:), video_attributes(uid: "653586a777d93c5815404e9a73b85527", live_input: nil, name: "uploaded video")])

        get admin_live_stream_archives_path

        expect(response.body).to include("kaigionrails-2026-magenta-raw 17 Oct 26 00:29 UTC")
        expect(response.body).not_to include("uploaded video")
      end

      it "shows 50 recordings and links to the older ones after the 50th when 51 come back" do
        stub_ready_videos(recordings(51))

        get admin_live_stream_archives_path

        expect(watch_links.size).to eq(50)
        expect(response.body).not_to include("recording 51")
        expect(response.body).to include(%(href="#{admin_live_stream_archives_path(before: "2026-10-16T23:11:00.000000Z")}"))
        expect(response.body).not_to include("Newest")
      end

      it "does not link to older ones when 50 or fewer come back" do
        stub_ready_videos(recordings(50))

        get admin_live_stream_archives_path

        expect(watch_links.size).to eq(50)
        expect(response.body).not_to include("Older")
      end

      it "takes the cursor from the 50th video even when uploaded videos are among them" do
        videos = recordings(51)
        videos[0] = videos[0].merge(liveInput: nil)
        stub_ready_videos(videos)

        get admin_live_stream_archives_path

        expect(watch_links.size).to eq(49)
        expect(response.body).to include(%(href="#{admin_live_stream_archives_path(before: "2026-10-16T23:11:00.000000Z")}"))
      end

      it "passes before to the API in UTC and links to the newest ones" do
        stub_ready_videos(recordings(1), query: {before: "2026-10-16T23:11:00.000000Z"})

        get admin_live_stream_archives_path(before: "2026-10-17T08:11:00+09:00")

        expect(response).to have_http_status(200)
        expect(response.body).to include(%(href="#{admin_live_stream_archives_path}">Newest))
      end

      it "shows the newest ones for before that is not a time" do
        stub_ready_videos(recordings(1))

        get admin_live_stream_archives_path(before: "not-a-time")

        expect(response).to have_http_status(200)
        expect(response.body).not_to include("Newest")
      end

      it "tells that there are no archives" do
        stub_ready_videos([])

        get admin_live_stream_archives_path

        expect(response.body).to include("No archives")
      end

      it "alerts when the API fails" do
        stub_request(:get, stream_url).with(query: {status: "ready", limit: "51"}).to_return(
          status: 403,
          body: JSON.dump(success: false, errors: [{code: 10000, message: "Authentication error"}], result: nil),
          headers: {"Content-Type": "application/json"}
        )

        get admin_live_stream_archives_path

        expect(response).to have_http_status(200)
        expect(response.body).to include("Failed to list the archives from Cloudflare")
        expect(response.body).to include("No archives")
      end

      it "alerts when the API times out" do
        stub_request(:get, stream_url).with(query: {status: "ready", limit: "51"}).to_timeout

        get admin_live_stream_archives_path

        expect(response).to have_http_status(200)
        expect(response.body).to include("Failed to list the archives from Cloudflare")
      end
    end

    describe "GET /admin/live_stream_archives/:id" do
      it "plays the recording on the Stream Player" do
        FactoryBot.create(
          :cloudflare_stream_live_stream,
          event: event,
          uid: magenta_uid,
          name: "kaigionrails-2026-magenta-raw",
          stream_raw_response: {"result" => {"meta" => {"name" => "kaigionrails-2026-magenta-raw", "hall" => "magenta", "lang" => "ja"}}}
        )
        stub_video(uid, success: true, errors: [], result: video_attributes(uid:))

        get admin_live_stream_archive_path(uid)

        expect(response).to have_http_status(200)
        expect(response.body).to include(%(<iframe src="https://customer-xxx.cloudflarestream.com/#{uid}/iframe"))
        expect(response.body).to include("kaigionrails-2026-magenta-raw (Kaigi on Rails 2026 / hall: magenta / lang: ja)")
        expect(response.body).to include("created: 2026-10-17 09:29 / duration: 8:42:21")
        expect(response.body).to include("uid: #{uid}")
        expect(response.body).to include("Back to archives")
      end

      it "shows the uid of a live input that is not registered in the app" do
        stub_video(uid, success: true, errors: [], result: video_attributes(uid:))

        get admin_live_stream_archive_path(uid)

        expect(response.body).to include("live input: #{magenta_uid} (not registered)")
      end

      it "is not found for an ongoing broadcast" do
        stub_video(uid, success: true, errors: [], result: video_attributes(uid:, state: "live-inprogress"))

        get admin_live_stream_archive_path(uid)

        expect(response).to have_http_status(404)
      end

      it "is not found for an uploaded video, which has no live input" do
        stub_video(uid, success: true, errors: [], result: video_attributes(uid:, live_input: nil))

        get admin_live_stream_archive_path(uid)

        expect(response).to have_http_status(404)
      end

      it "is not found when the API fails" do
        stub_video(uid, success: false, errors: [{code: 10005, message: "Not Found"}], result: nil)

        get admin_live_stream_archive_path(uid)

        expect(response).to have_http_status(404)
      end

      it "goes back to the list with an alert when the API times out" do
        stub_request(:get, "#{stream_url}/#{uid}").to_timeout

        get admin_live_stream_archive_path(uid)

        expect(response).to redirect_to(admin_live_stream_archives_path)
        expect(flash[:alert]).to eq("Failed to fetch the archive from Cloudflare")
      end

      it "is not found for an id that is not a uid without calling the API" do
        get "/admin/live_stream_archives/not-a-uid"

        expect(response).to have_http_status(404)
        expect(a_request(:get, %r{api.cloudflare.com})).not_to have_been_made
      end
    end
  end

  context "as a participant" do
    before { sign_in(FactoryBot.create(:user)) }

    it "redirects the list to the root without calling the API" do
      get admin_live_stream_archives_path

      expect(response).to redirect_to(root_path)
      expect(a_request(:get, %r{api.cloudflare.com})).not_to have_been_made
    end

    it "redirects the recording to the root without calling the API" do
      get admin_live_stream_archive_path(uid)

      expect(response).to redirect_to(root_path)
      expect(a_request(:get, %r{api.cloudflare.com})).not_to have_been_made
    end
  end
end
