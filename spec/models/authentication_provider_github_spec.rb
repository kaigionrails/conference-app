require "rails_helper"

RSpec.describe AuthenticationProviderGithub, type: :model do
  describe "self.create_user_from_auth_hash" do
    let(:event) { FactoryBot.create(:event) }
    let(:auth_hash) { {"info" => {"nickname" => "octocat"}, "uid" => "583231"} } # https://github.com/octocat
    let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: event) }

    before do
      stub_request(:get, "https://api.github.com/user/583231")
        .to_return(
          body: {avatar_url: "https://avatars.example.invalid/octocat.png"}.to_json,
          headers: {"Content-Type" => "application/json"}
        )
      stub_request(:get, "https://avatars.example.invalid/octocat.png")
        .to_return(
          body: Rails.root.join("spec/assets/sample.png").binread,
          headers: {"Content-Type" => "image/png"}
        )
    end

    it "should success user and profile image from GitHub" do
      expect {
        AuthenticationProviderGithub.create_user_from_auth_hash(auth_hash)
      }.to change { AuthenticationProviderGithub.count }.by(1).and change { User.count }.by(1).and change { Profile.count }.by(1)
      user = User.find_by!(name: "octocat")
      expect(user.profile.name).to eq "octocat"
      expect(user.profile.images).to be_attached
    end
  end
end
