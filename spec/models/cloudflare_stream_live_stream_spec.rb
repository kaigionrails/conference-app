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

      it "keeps the CloudflareStreamLiveStream with destroy_when_gone: false" do
        expect(live_stream.update_stream(destroy_when_gone: false)).to eq false
        expect(CloudflareStreamLiveStream.where(uid: "uidfortest").count).to eq 1
      end
    end
  end

  describe "#retrieve_videos" do
    pending
  end

  describe "#url" do
    pending
  end

  describe "#hall and #lang" do
    it "returns the values in the meta" do
      live_stream = FactoryBot.build(:cloudflare_stream_live_stream, stream_raw_response: {"result" => {"meta" => {"hall" => "magenta", "lang" => "ja"}}})
      expect(live_stream.hall).to eq "magenta"
      expect(live_stream.lang).to eq "ja"
    end

    it "returns nil without the meta" do
      live_stream = FactoryBot.build(:cloudflare_stream_live_stream, stream_raw_response: {"result" => {}})
      expect(live_stream.hall).to be_nil
      expect(live_stream.lang).to be_nil
    end

    it "returns nil without the response" do
      live_stream = FactoryBot.build(:cloudflare_stream_live_stream, stream_raw_response: nil)
      expect(live_stream.hall).to be_nil
      expect(live_stream.lang).to be_nil
    end
  end

  describe "#test?" do
    def live_stream_with_meta(meta)
      FactoryBot.build(:cloudflare_stream_live_stream, stream_raw_response: {"result" => {"meta" => meta}})
    end

    it "is true with any value in the test key" do
      expect(live_stream_with_meta({"test" => "true"}).test?).to eq true
      expect(live_stream_with_meta({"test" => "1"}).test?).to eq true
    end

    it "is false with a blank value or without the test key" do
      expect(live_stream_with_meta({"test" => ""}).test?).to eq false
      expect(live_stream_with_meta({"test" => " "}).test?).to eq false
      expect(live_stream_with_meta({"test" => false}).test?).to eq false
      expect(live_stream_with_meta({"name" => "test stream"}).test?).to eq false
    end
  end
end
