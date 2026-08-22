require "rails_helper"

RSpec.describe SocialAnnouncementPostJob, type: :job do
  include ActiveJob::TestHelper

  let(:announcement) { FactoryBot.create(:social_announcement) }
  let(:text) { FactoryBot.create(:social_announcement_text, :approved, social_announcement: announcement, body: "hello") }
  let(:target) { FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "mastodon") }
  let!(:post) { FactoryBot.create(:social_announcement_post, social_announcement_text: text, social_announcement_target_platform: target) }

  it "marks the post succeeded with the result" do
    stub = stub_request(:post, "https://mastodon.test/api/v1/statuses")
      .with(headers: {"Idempotency-Key" => "social-announcement:#{text.id}:#{target.id}:#{text.current_body_digest}:#{announcement.current_media_digest}"})
      .to_return(status: 200, body: {id: "9", url: "https://mastodon.test/@k/9"}.to_json, headers: {"Content-Type" => "application/json"})

    described_class.perform_now(text.id, target.id)

    expect(stub).to have_been_requested
    post.reload
    expect(post).to be_succeeded
    expect(post.remote_id).to eq("9")
    expect(post.posted_body).to eq("hello")
    expect(post.posted_media_digest).to eq(announcement.current_media_digest)
    expect(announcement.reload.published_at).to eq(post.posted_at)
  end

  it "passes the alt text of the text's locale to the client" do
    FactoryBot.create(:social_announcement_media, social_announcement: announcement, alt_text_ja: "ja-alt", alt_text_en: "en-alt")
    SocialAnnouncementTextReview.create_for!(text, reviewer: FactoryBot.create(:user, role: "organizer"))
    upload = stub_request(:post, "https://mastodon.test/api/v2/media")
      .with { |req| req.body.include?("ja-alt") && !req.body.include?("en-alt") }
      .to_return(status: 200, body: {id: "m1"}.to_json, headers: {"Content-Type" => "application/json"})
    stub_request(:post, "https://mastodon.test/api/v1/statuses")
      .to_return(status: 200, body: {id: "9", url: "https://mastodon.test/@k/9"}.to_json, headers: {"Content-Type" => "application/json"})

    described_class.perform_now(text.id, target.id)
    expect(upload).to have_been_requested
  end

  it "reverts the post to pending when the client raises, so a retry can claim it again" do
    stub_request(:post, "https://mastodon.test/api/v1/statuses").to_return(status: 500, body: "oops")
    expect { described_class.perform_now(text.id, target.id) }.to have_enqueued_job(described_class)
    expect(post.reload).to be_pending
  end

  it "does not post when another job has already claimed the post" do
    post.update!(status: "posting")
    described_class.perform_now(text.id, target.id)
    expect(a_request(:post, "https://mastodon.test/api/v1/statuses")).not_to have_been_made
    expect(post.reload).to be_posting
  end

  it "keeps the rotated X refresh token even when the post fails after the refresh" do
    x_target = FactoryBot.create(:social_announcement_target_platform, social_announcement: announcement, platform: "x")
    x_post = FactoryBot.create(:social_announcement_post, social_announcement_text: text, social_announcement_target_platform: x_target)
    token = FactoryBot.create(:social_oauth_token, refresh_token: "old-refresh", access_token_expires_at: 1.minute.from_now)
    stub_request(:post, "https://api.x.com/2/oauth2/token")
      .to_return(status: 200, body: {access_token: "new-access", refresh_token: "new-refresh", expires_in: 7200}.to_json, headers: {"Content-Type" => "application/json"})
    stub_request(:post, "https://api.x.com/2/tweets").to_return(status: 503, body: "{}", headers: {"Content-Type" => "application/json"})

    described_class.perform_now(text.id, x_target.id)

    expect(token.reload.refresh_token).to eq("new-refresh")
    expect(token.access_token).to eq("new-access")
    expect(x_post.reload).to be_pending
  end

  it "does not record success when the posting claim was lost meanwhile, and raises for a human" do
    client = instance_double(Social::MastodonClient)
    allow(Social).to receive(:client_for).and_return(client)
    allow(client).to receive(:post) {
      # 投稿中に stale 扱いで再 dispatch され、別ジョブが claim し直した状況
      SocialAnnouncementPost.where(id: post.id).update_all(status: "pending")
      Social::Result.new(remote_id: "dup", remote_url: "https://mastodon.test/@k/dup")
    }

    expect { described_class.perform_now(text.id, target.id) }
      .to raise_error(SocialAnnouncementPostJob::ClaimLost, %r{https://mastodon.test/@k/dup})
    expect(post.reload).to be_pending
    expect(post.remote_id).to be_nil
  end

  it "returns early when already succeeded" do
    post.update!(status: "succeeded", remote_id: "1", remote_url: "https://example.test/p/1", posted_body: "b", posted_media_digest: "d", posted_at: Time.current)
    described_class.perform_now(text.id, target.id)
    expect(a_request(:post, "https://mastodon.test/api/v1/statuses")).not_to have_been_made
  end

  it "does nothing when the text is not approved" do
    text.update!(body: "changed")
    described_class.perform_now(text.id, target.id)
    expect(a_request(:post, "https://mastodon.test/api/v1/statuses")).not_to have_been_made
    expect(post.reload).to be_pending
  end

  it "marks the post failed after retries are exhausted" do
    stub_request(:post, "https://mastodon.test/api/v1/statuses").to_return(status: 500, body: "oops")
    perform_enqueued_jobs do
      described_class.perform_later(text.id, target.id)
    end
    post.reload
    expect(post).to be_failed
    expect(post.last_error).to match(/500/)
    expect(a_request(:post, "https://mastodon.test/api/v1/statuses")).to have_been_made.times(5)
  end

  it "does not call external HTTP in dry-run mode" do
    allow(Social).to receive(:dry_run?).and_return(true)
    described_class.perform_now(text.id, target.id)
    expect(post.reload).to be_succeeded
    expect(post.remote_id).to start_with("dry-run-")
    expect(WebMock).not_to have_requested(:any, /.*/)
  end
end
