require "rails_helper"

RSpec.describe Social::XClient do
  let(:client) { described_class.new }
  let!(:token) { FactoryBot.create(:social_oauth_token, access_token: "user-access") }

  it "posts a tweet with the user access token as bearer" do
    stub = stub_request(:post, "https://api.x.com/2/tweets")
      .with(headers: {"Authorization" => "Bearer user-access"}, body: {text: "hello"}.to_json)
      .to_return(status: 201, body: {data: {id: "777", text: "hello"}}.to_json, headers: {"Content-Type" => "application/json"})

    result = client.post(text: "hello")
    expect(stub).to have_been_requested
    expect(result.remote_id).to eq("777")
    expect(result.remote_url).to eq("https://x.com/testuser/status/777")
  end

  it "uploads media then sets alt text metadata" do
    medium = Social::Attachment.new(file: FactoryBot.create(:social_announcement_media).file, alt_text: "alt")
    upload = stub_request(:post, "https://api.x.com/2/media/upload")
      .with { |req| req.headers["Content-Type"].start_with?("multipart/form-data") && req.body.include?("tweet_image") }
      .to_return(status: 200, body: {data: {id: "m1"}}.to_json, headers: {"Content-Type" => "application/json"})
    metadata = stub_request(:post, "https://api.x.com/2/media/metadata")
      .with(body: {id: "m1", metadata: {alt_text: {text: "alt"}}}.to_json)
      .to_return(status: 200, body: {data: {}}.to_json, headers: {"Content-Type" => "application/json"})
    tweet = stub_request(:post, "https://api.x.com/2/tweets")
      .with(body: {text: "hello", media: {media_ids: ["m1"]}}.to_json)
      .to_return(status: 201, body: {data: {id: "778"}}.to_json, headers: {"Content-Type" => "application/json"})

    client.post(text: "hello", media: [medium])
    expect(upload).to have_been_requested
    expect(metadata).to have_been_requested
    expect(tweet).to have_been_requested
  end

  it "refreshes the token and retries once on 401" do
    stub_request(:post, "https://api.x.com/2/tweets")
      .with(headers: {"Authorization" => "Bearer user-access"})
      .to_return(status: 401, body: "{}", headers: {"Content-Type" => "application/json"})
    refresh = stub_request(:post, "https://api.x.com/2/oauth2/token")
      .to_return(status: 200, body: {access_token: "new-access", refresh_token: "new-refresh", expires_in: 7200}.to_json, headers: {"Content-Type" => "application/json"})
    retry_stub = stub_request(:post, "https://api.x.com/2/tweets")
      .with(headers: {"Authorization" => "Bearer new-access"})
      .to_return(status: 201, body: {data: {id: "779"}}.to_json, headers: {"Content-Type" => "application/json"})

    client.post(text: "hello")
    expect(refresh).to have_been_requested
    expect(retry_stub).to have_been_requested
    expect(token.reload.access_token).to eq("new-access")
  end

  it "raises PostError when X is not connected" do
    token.destroy!
    expect { client.post(text: "hello") }.to raise_error(Social::PostError, /not connected/)
  end

  it "raises PostError on API error" do
    stub_request(:post, "https://api.x.com/2/tweets").to_return(status: 403, body: {detail: "forbidden"}.to_json, headers: {"Content-Type" => "application/json"})
    expect { client.post(text: "hello") }.to raise_error(Social::PostError, /403/)
  end

  it "sets connection timeouts" do
    conn = client.send(:connection, "token")
    expect(conn.options.open_timeout).to eq(Social::HTTP_TIMEOUTS[:open_timeout])
    expect(conn.options.timeout).to eq(Social::HTTP_TIMEOUTS[:timeout])
  end
end
