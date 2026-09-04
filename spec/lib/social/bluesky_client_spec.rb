require "rails_helper"

RSpec.describe Social::BlueskyClient do
  let(:client) { described_class.new }
  let(:session_body) { {accessJwt: "jwt", did: "did:plc:abc"}.to_json }

  before do
    stub_request(:post, "https://bsky.social/xrpc/com.atproto.server.createSession")
      .with(body: {identifier: "test.bsky.social", password: "test"}.to_json)
      .to_return(status: 200, body: session_body, headers: {"Content-Type" => "application/json"})
  end

  it "creates a session and a post record with langs" do
    create = stub_request(:post, "https://bsky.social/xrpc/com.atproto.repo.createRecord")
      .with(headers: {"Authorization" => "Bearer jwt"}) { |req|
        body = JSON.parse(req.body)
        body["repo"] == "did:plc:abc" && body["record"]["text"] == "hello" && body["record"]["langs"] == ["ja"]
      }
      .to_return(status: 200, body: {uri: "at://did:plc:abc/app.bsky.feed.post/rkey1", cid: "c"}.to_json, headers: {"Content-Type" => "application/json"})

    result = client.post(text: "hello", langs: ["ja"])
    expect(create).to have_been_requested
    expect(result.remote_id).to eq("at://did:plc:abc/app.bsky.feed.post/rkey1")
    expect(result.remote_url).to eq("https://bsky.app/profile/test.bsky.social/post/rkey1")
  end

  it "uploads blobs and embeds images with alt" do
    medium = Social::Attachment.new(file: FactoryBot.create(:social_announcement_media).file, alt_text: "alt")
    upload = stub_request(:post, "https://bsky.social/xrpc/com.atproto.repo.uploadBlob")
      .with(headers: {"Authorization" => "Bearer jwt", "Content-Type" => "image/png"})
      .to_return(status: 200, body: {blob: {"$type" => "blob", :ref => {"$link" => "x"}}}.to_json, headers: {"Content-Type" => "application/json"})
    create = stub_request(:post, "https://bsky.social/xrpc/com.atproto.repo.createRecord")
      .with { |req|
        embed = JSON.parse(req.body)["record"]["embed"]
        embed["$type"] == "app.bsky.embed.images" && embed["images"].first["alt"] == "alt"
      }
      .to_return(status: 200, body: {uri: "at://did:plc:abc/app.bsky.feed.post/rkey2"}.to_json, headers: {"Content-Type" => "application/json"})

    client.post(text: "hello", media: [medium], langs: ["en"])
    expect(upload).to have_been_requested
    expect(create).to have_been_requested
  end

  it "raises PostError when auth fails" do
    stub_request(:post, "https://bsky.social/xrpc/com.atproto.server.createSession").to_return(status: 401, body: "{}")
    expect { client.post(text: "hello") }.to raise_error(Social::PostError, /auth failed/)
  end

  it "sets connection timeouts" do
    conn = client.send(:connection)
    expect(conn.options.open_timeout).to eq(Social::HTTP_TIMEOUTS[:open_timeout])
    expect(conn.options.timeout).to eq(Social::HTTP_TIMEOUTS[:timeout])
  end
end
