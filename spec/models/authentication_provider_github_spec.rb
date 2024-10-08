require "rails_helper"

RSpec.describe AuthenticationProviderGithub, type: :model do
  describe "self.create_user_from_auth_hash" do
    let(:event) { FactoryBot.create(:event) }
    let(:auth_hash) { {"info" => {"nickname" => "octocat"}, "uid" => "583231"} } # https://github.com/octocat
    let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: event) }

    it "should success user and profile image from GitHub" do
      allow_any_instance_of(Profile).to receive(:fetch_profile_image_from_github).and_return(
        StringIO.new(Rails.root.join("spec/assets/sample.png").read)
      )
      expect {
        AuthenticationProviderGithub.create_user_from_auth_hash(auth_hash)
      }.to change { AuthenticationProviderGithub.count }.by(1).and change { User.count }.by(1).and change { Profile.count }.by(1)
      user = User.find_by!(name: "octocat")
      expect(user.profile.name).to eq "octocat"
    end
  end
end
