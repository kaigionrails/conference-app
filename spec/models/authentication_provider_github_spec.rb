require 'rails_helper'

RSpec.describe AuthenticationProviderGithub, type: :model do
  describe "self.create_user_from_auth_hash" do
    let(:auth_hash) { { "info" => { "nickname" => "octocat" }, "uid" => "583231"} } # https://github.com/octocat

    it "should success user and profile image from GitHub" do
      allow_any_instance_of(Profile).to receive(:fetch_profile_image_from_github).and_return(
        StringIO.new(File.read(Rails.root.join("spec", "assets", "sample.png")))
        )
      expect {
        AuthenticationProviderGithub.create_user_from_auth_hash(auth_hash)
      }.to change { AuthenticationProviderGithub.count }.by(1).and change { User.count }.by(1).and change { Profile.count }.by(1)
      user = User.find_by!(name: "octocat")
      expect(user.profile.name).to eq "octocat"
      expect(user.profile.images.size).to eq 1
    end
  end
end
