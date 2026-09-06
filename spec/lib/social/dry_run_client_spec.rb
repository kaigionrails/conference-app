require "rails_helper"

RSpec.describe Social::DryRunClient do
  it "does not call the inner client and returns a fake result" do
    inner = instance_double(Social::MastodonClient)
    expect(inner).not_to receive(:post)
    result = described_class.new(inner).post(text: "hello")
    expect(result.remote_id).to start_with("dry-run-")
    expect(result.remote_url).to eq("https://social.test/posts/dry-run")
  end
end
