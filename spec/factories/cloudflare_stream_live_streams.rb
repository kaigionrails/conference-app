FactoryBot.define do
  factory :cloudflare_stream_live_stream do
    event
    uid { "testuid" }
    name { "test stream" }
    stream_raw_response { {"result" => {"uid" => "testuid", "meta" => {"name" => "test stream"}}} }
    stream_videos_raw_response { {"result" => [{"playback" => {"hls" => "https://example.com"}}]} }
  end
end
