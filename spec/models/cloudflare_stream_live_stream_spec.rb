require "rails_helper"

RSpec.describe CloudflareStreamLiveStream, type: :model do
  let!(:event) { FactoryBot.create(:event, :make_ongoing) }
  describe ".create_by_stream_uid" do
    before do
      stub_request(:get, "https://api.cloudflare.com/client/v4/accounts/testtesttesttest/stream/live_inputs/uidfortest")
        .with(
          headers: {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "Authorization" => "Bearer testtesttesttest",
            "Content-Type" => "application/json",
            "User-Agent" => %r{Faraday .+}
          }
        ).to_return(
          status: 200, body: JSON.dump(response),
          headers: {"Content-Type": "application/json"}
        )
    end
    context "api call succeeded" do
      let(:response) {
        {
          errors: [],
          result: {
            uid: "uidfortest",
            meta: {
              name: "test stream"
            },
            webRTC: {
              url: "https://example.com"
            }
          }
        }
      }

      it "creates a new CloudflareStreamLiveStream" do
        expect {
          CloudflareStreamLiveStream.create_by_stream_uid("uidfortest")
        }.to change { CloudflareStreamLiveStream.count }.by(1)
      end
    end

    context "api returns error response" do
      let(:response) {
        {
          errors: [{code: 1000}],
          result: {}
        }
      }

      it "create nothing" do
        expect {
          CloudflareStreamLiveStream.create_by_stream_uid("uidfortest")
        }.to change { CloudflareStreamLiveStream.count }.by(0)
      end
    end
  end

  describe "#update_stream" do
    let(:live_stream) { FactoryBot.create(:cloudflare_stream_live_stream, uid: "uidfortest") }

    context "api call succeeded" do
      before do
        stub_request(:get, "https://api.cloudflare.com/client/v4/accounts/testtesttesttest/stream/live_inputs/uidfortest")
          .with(
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Authorization" => "Bearer testtesttesttest",
              "Content-Type" => "application/json",
              "User-Agent" => %r{Faraday .+}
            }
          ).to_return(
            status: 200, body: JSON.dump(live_response),
            headers: {"Content-Type": "application/json"}
          )
        stub_request(:get, "https://api.cloudflare.com/client/v4/accounts/testtesttesttest/stream/live_inputs/uidfortest/videos")
          .with(
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Authorization" => "Bearer testtesttesttest",
              "Content-Type" => "application/json",
              "User-Agent" => %r{Faraday .+}
            }
          )
          .to_return(status: 200, body: JSON.dump(live_videos_response), headers: {"Content-Type": "application/json"})
      end

      let(:live_response) {
        {
          success: true,
          errors: [],
          result: {
            uid: "uidfortest",
            meta: {
              name: "test stream test stream test"
            },
            webRTC: {
              url: "https://example.com/sampleurl"
            }
          }
        }
      }
      let(:live_videos_response) {
        {
          success: true,
          errors: [],
          result:
            [{
              uid: "uidfortest",
              meta: {
                name: "test stream test stream test"
              },
              playback: {hls: "https://example.com/hls"}
            }]
        }
      }

      it "should update the CloudflareStreamLiveStream" do
        live_stream.update_stream
        expect(live_stream.name).to eq "test stream test stream test"
        expect(live_stream.stream_raw_response["result"]["webRTC"]["url"]).to eq "https://example.com/sampleurl"
        expect(live_stream.stream_videos_raw_response["result"][0]["playback"]["hls"]).to eq "https://example.com/hls"
      end
    end

    context "the live input has gone" do
      before do
        stub_request(:get, "https://api.cloudflare.com/client/v4/accounts/testtesttesttest/stream/live_inputs/uidfortest")
          .with(
            headers: {
              "Accept" => "*/*",
              "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
              "Authorization" => "Bearer testtesttesttest",
              "Content-Type" => "application/json",
              "User-Agent" => %r{Faraday .+}
            }
          ).to_return(
            status: 200, body: JSON.dump(live_response),
            headers: {"Content-Type": "application/json"}
          )
      end

      let(:live_response) {
        {
          success: false,
          errors: [{code: 1000}]
        }
      }
      it "should destroy the CloudflareStreamLiveStream" do
        live_stream.update_stream
        expect(CloudflareStreamLiveStream.where(uid: "uidfortest").count).to eq 0
      end
    end
  end

  describe "#retrieve_videos" do
    pending
  end

  describe "#url" do
    pending
  end
end
