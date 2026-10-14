require "rails_helper"

RSpec.describe "LiveStreams", type: :request do
  describe "GET /:event_slug/live" do
    context "when event not found" do
      let(:user) { FactoryBot.create(:user, role: "organizer") }
      before { sign_in user }
      it "returns 404" do
        get "/1999/live"
        expect(response).to have_http_status(404)
      end
    end

    context "when event found and ongoing" do
      let(:user) { FactoryBot.create(:user) }
      let!(:event) { FactoryBot.create(:event, :make_ongoing, slug: "2025", end_date: 1.minutes.since) }

      context "when not logged in" do
        it "redirect to check-in path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/2025/live/checkin"
        end
      end

      context "when logged in but have not ticket" do
        before do
          sign_in user
        end

        it "redirect to check-in path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/2025/live/checkin"
        end
      end

      context "when logged in and have ticket" do
        let!(:tito_ticket) { FactoryBot.create(:tito_ticket, user: user, event: event, state: "complete") }
        before do
          sign_in user
        end

        it "should be viewable" do
          get "/2025/live"
          expect(response).to have_http_status(200)
        end

        it "passes the YOYO Translate URLs of the event to the page" do
          FactoryBot.create(:yoyo_translate_setting, event: event)

          get "/2025/live"

          expect(response.body).to include('data-live-streams-yoyo-translate-magenta-hall-url-value="https://example.com/magenta"')
          expect(response.body).to include('data-live-streams-yoyo-translate-lime-hall-url-value="https://example.com/lime"')
        end

        it "passes empty YOYO Translate URLs without the setting" do
          get "/2025/live"

          expect(response.body).to include('data-live-streams-yoyo-translate-magenta-hall-url-value=""')
          expect(response.body).to include('data-live-streams-yoyo-translate-lime-hall-url-value=""')
        end

        it "passes the streams of the live inputs found by their meta to the page" do
          [
            ["Magenta JA", "magenta", "ja"],
            ["Magenta EN", "magenta", "en"],
            ["Lime JA", "lime", "ja"],
            ["Lime EN", "lime", "en"]
          ].each do |name, hall, lang|
            FactoryBot.create(
              :cloudflare_stream_live_stream,
              event: event,
              name: name,
              stream_raw_response: {"result" => {
                "meta" => {"name" => name, "hall" => hall, "lang" => lang},
                "playback" => {"hls" => "https://example.com/#{hall}-#{lang}.m3u8"}
              }},
              stream_videos_raw_response: {"result" => [{"playback" => {"hls" => "https://example.com/recording.m3u8"}}]}
            )
          end

          get "/2025/live"

          expect(response.body).to include('data-live-streams-magenta-ja-value="https://example.com/magenta-ja.m3u8"')
          expect(response.body).to include('data-live-streams-magenta-en-value="https://example.com/magenta-en.m3u8"')
          expect(response.body).to include('data-live-streams-lime-ja-value="https://example.com/lime-ja.m3u8"')
          expect(response.body).to include('data-live-streams-lime-en-value="https://example.com/lime-en.m3u8"')
          # The recording of the last broadcast is not played.
          expect(response.body).not_to include("https://example.com/recording.m3u8")
        end

        it "passes empty streams without the live inputs" do
          get "/2025/live"

          expect(response.body).to include('data-live-streams-magenta-ja-value=""')
          expect(response.body).to include('data-live-streams-magenta-en-value=""')
          expect(response.body).to include('data-live-streams-lime-ja-value=""')
          expect(response.body).to include('data-live-streams-lime-en-value=""')
        end

        it "passes an empty stream for a live input whose response has no playback URL" do
          FactoryBot.create(
            :cloudflare_stream_live_stream,
            event: event,
            stream_raw_response: {"result" => {"meta" => {"name" => "Magenta JA", "hall" => "magenta", "lang" => "ja"}}}
          )

          get "/2025/live"

          expect(response).to have_http_status(200)
          expect(response.body).to include('data-live-streams-magenta-ja-value=""')
        end

        it "passes the live input with the test key only as the stream of #test" do
          FactoryBot.create(
            :cloudflare_stream_live_stream,
            event: event,
            stream_raw_response: {"result" => {
              "meta" => {"name" => "test stream", "test" => "true", "hall" => "magenta", "lang" => "ja"},
              "playback" => {"hls" => "https://example.com/test.m3u8"}
            }}
          )

          get "/2025/live"

          expect(response.body).to include('data-live-streams-test-value="https://example.com/test.m3u8"')
          expect(response.body).to include('data-live-streams-magenta-ja-value=""')
        end

        it "does not assign the live inputs by their names or by a meta that does not match exactly" do
          FactoryBot.create(
            :cloudflare_stream_live_stream,
            event: event,
            name: "kaigionrails-2026-magenta-ja",
            stream_raw_response: {"result" => {
              "meta" => {"name" => "kaigionrails-2026-magenta-ja"},
              "playback" => {"hls" => "https://example.com/named.m3u8"}
            }}
          )
          FactoryBot.create(
            :cloudflare_stream_live_stream,
            event: event,
            stream_raw_response: {"result" => {
              "meta" => {"name" => "Magenta JA", "hall" => "Magenta", "lang" => "ja"},
              "playback" => {"hls" => "https://example.com/capitalized.m3u8"}
            }}
          )

          get "/2025/live"

          expect(response.body).to include('data-live-streams-magenta-ja-value=""')
        end

        it "starts with the JA audio" do
          get "/2025/live"

          expect(response.body).to include('data-live-streams-selected-audio-value="ja"')
        end

        it "starts with the EN audio in the en locale" do
          get "/2025/live?locale=en"

          expect(response.body).to include('data-live-streams-selected-audio-value="en"')
        end
      end

      context "when logged in and organizer" do
        before do
          user.update(role: "organizer")
          sign_in user
        end

        it "should be viewable" do
          get "/2025/live"
          expect(response).to have_http_status(200)
        end
      end

      context "when logged in an operator" do
        before do
          user.update(role: "operator")
          sign_in user
        end

        it "should be viewable" do
          get "/2025/live"
          expect(response).to have_http_status(200)
        end
      end
    end

    context "when event found but over" do
      let(:user) { FactoryBot.create(:user) }
      let!(:event) { FactoryBot.create(:event, :make_ongoing, slug: "2025", end_date: 1.minute.ago) }

      context "when not logged in" do
        it "redirect to check-in path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/2025/live/checkin"
        end
      end

      context "when logged in but have not ticket" do
        before do
          sign_in user
        end

        it "redirect to check-in path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/2025/live/checkin"
        end
      end

      context "when logged in and have ticket" do
        let!(:tito_ticket) { FactoryBot.create(:tito_ticket, user: user, event: event, state: "complete") }
        before do
          sign_in user
        end

        it "redirect to root path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/"
        end
      end

      context "when logged in and organizer" do
        before do
          user.update(role: "organizer")
          sign_in user
        end

        it "should be viewable" do
          get "/2025/live"
          expect(response).to have_http_status(200)
        end
      end

      context "when logged in an operator" do
        before do
          user.update(role: "operator")
          sign_in user
        end

        it "redirect to root path" do
          get "/2025/live"
          expect(response).to have_http_status(302)
          expect(response).to redirect_to "/"
        end
      end
    end
  end
end
