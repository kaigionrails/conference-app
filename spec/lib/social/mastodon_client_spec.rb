require "rails_helper"

RSpec.describe Social::MastodonClient do
  let(:client) { described_class.new }

  it "posts a status with bearer token and idempotency key" do
    stub = stub_request(:post, "https://mastodon.test/api/v1/statuses")
      .with(
        headers: {"Authorization" => "Bearer test", "Idempotency-Key" => "key-1"},
        body: {status: "hello", visibility: "public"}.to_json
      )
      .to_return(status: 200, body: {id: "1", url: "https://mastodon.test/@k/1"}.to_json, headers: {"Content-Type" => "application/json"})

    result = client.post(text: "hello", idempotency_key: "key-1")
    expect(stub).to have_been_requested
    expect(result.remote_id).to eq("1")
    expect(result.remote_url).to eq("https://mastodon.test/@k/1")
  end

  it "uploads media as multipart then references media_ids" do
    medium = Social::Attachment.new(file: FactoryBot.create(:social_announcement_media).file, alt_text: "alt")
    upload = stub_request(:post, "https://mastodon.test/api/v2/media")
      .with { |req| req.headers["Content-Type"].start_with?("multipart/form-data") && req.body.include?("description") && req.body.include?("sample.png") }
      .to_return(status: 202, body: {id: "m1"}.to_json, headers: {"Content-Type" => "application/json"})
    status = stub_request(:post, "https://mastodon.test/api/v1/statuses")
      .with(body: {status: "hello", visibility: "public", media_ids: ["m1"]}.to_json)
      .to_return(status: 200, body: {id: "2", url: "https://mastodon.test/@k/2"}.to_json, headers: {"Content-Type" => "application/json"})

    client.post(text: "hello", media: [medium])
    expect(upload).to have_been_requested
    expect(status).to have_been_requested
  end

  it "raises PostError on failure" do
    stub_request(:post, "https://mastodon.test/api/v1/statuses").to_return(status: 422, body: "{}")
    expect { client.post(text: "hello") }.to raise_error(Social::PostError, /422/)
  end

  it "refuses a non-https base_url without sending the token" do
    config = ActiveSupport::OrderedOptions.new
    config.mastodon_base_url = "http://mastodon.test"
    config.mastodon_access_token = "test"
    expect { described_class.new(config: config).post(text: "hello") }.to raise_error(Social::PostError, /https/)
    expect(WebMock).not_to have_requested(:any, /.*/)
  end

  it "raises PostError when credentials are missing" do
    expect { described_class.new(config: ActiveSupport::OrderedOptions.new).post(text: "hello") }.to raise_error(Social::PostError, /SOCIAL_MASTODON_BASE_URL/)
  end

  it "sets connection timeouts" do
    conn = client.send(:connection)
    expect(conn.options.open_timeout).to eq(Social::HTTP_TIMEOUTS[:open_timeout])
    expect(conn.options.timeout).to eq(Social::HTTP_TIMEOUTS[:timeout])
  end
end
