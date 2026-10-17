require "rails_helper"

RSpec.describe CloudflareStreamVideo, type: :model do
  let(:uid) { "19a1ab8a7d077bc66d5cd422f89cb986" }

  # A recording of a live input in the shape that the Stream API returns.
  def video_attributes(uid:, state: "ready", live_input: "1bf04fe9c7f78140478d182b90d32896", meta: {"name" => "kaigionrails-2026-magenta-raw 17 Oct 26 00:29 UTC"}, duration: 31341,
    thumbnail: "https://customer-xxx.cloudflarestream.com/#{uid}/thumbnails/thumbnail.jpg",
    preview: "https://customer-xxx.cloudflarestream.com/#{uid}/watch")
    {
      "uid" => uid,
      "liveInput" => live_input,
      "status" => {"state" => state},
      "meta" => meta,
      "created" => "2026-10-17T00:29:12.708196Z",
      "duration" => duration,
      "thumbnail" => thumbnail,
      "preview" => preview
    }
  end

  describe "#player_url" do
    it "plays the video on the customer subdomain of the preview URL" do
      video = CloudflareStreamVideo.new(video_attributes(uid:))

      expect(video.player_url).to eq("https://customer-xxx.cloudflarestream.com/#{uid}/iframe")
    end

    it "is nil until the encoding completes, when Stream gives no preview URL" do
      video = CloudflareStreamVideo.new(video_attributes(uid:, preview: nil))

      expect(video.player_url).to be_nil
    end
  end

  describe "#thumbnail_url" do
    it "resizes the thumbnail to the height without cropping it" do
      video = CloudflareStreamVideo.new(video_attributes(uid:))

      expect(video.thumbnail_url(height: 120)).to eq("https://customer-xxx.cloudflarestream.com/#{uid}/thumbnails/thumbnail.jpg?height=120&fit=clip")
    end

    it "keeps the query of the thumbnail URL" do
      video = CloudflareStreamVideo.new(video_attributes(uid:, thumbnail: "https://customer-xxx.cloudflarestream.com/#{uid}/thumbnails/thumbnail.jpg?time=1s"))

      expect(video.thumbnail_url(height: 120)).to eq("https://customer-xxx.cloudflarestream.com/#{uid}/thumbnails/thumbnail.jpg?time=1s&height=120&fit=clip")
    end

    it "is nil without a thumbnail" do
      video = CloudflareStreamVideo.new(video_attributes(uid:, thumbnail: nil))

      expect(video.thumbnail_url(height: 120)).to be_nil
    end
  end

  describe "#duration_text" do
    it "shows the hours, the minutes and the whole seconds" do
      expect(CloudflareStreamVideo.new(video_attributes(uid:, duration: 3723.9)).duration_text).to eq("1:02:03")
      expect(CloudflareStreamVideo.new(video_attributes(uid:, duration: 36000)).duration_text).to eq("10:00:00")
    end

    it "shows the hours even under an hour" do
      expect(CloudflareStreamVideo.new(video_attributes(uid:, duration: 123)).duration_text).to eq("0:02:03")
    end

    it "is nil while Stream does not know the duration" do
      expect(CloudflareStreamVideo.new(video_attributes(uid:, duration: -1)).duration_text).to be_nil
    end
  end

  describe "#archive?" do
    it "is true for a recording of a live input that is ready" do
      expect(CloudflareStreamVideo.new(video_attributes(uid:))).to be_archive
    end

    it "is false for an ongoing broadcast" do
      expect(CloudflareStreamVideo.new(video_attributes(uid:, state: "live-inprogress"))).not_to be_archive
    end

    it "is false for an uploaded video, which has no live input" do
      expect(CloudflareStreamVideo.new(video_attributes(uid:, live_input: nil))).not_to be_archive
    end
  end

  describe "#display_name" do
    it "is the name in the meta" do
      expect(CloudflareStreamVideo.new(video_attributes(uid:)).display_name).to eq("kaigionrails-2026-magenta-raw 17 Oct 26 00:29 UTC")
    end

    it "is the uid when the meta has no name" do
      expect(CloudflareStreamVideo.new(video_attributes(uid:, meta: {})).display_name).to eq(uid)
    end
  end
end
