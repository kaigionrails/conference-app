require "rails_helper"

RSpec.describe AuthenticationProviderGoogle, type: :model do
  let(:event) { FactoryBot.create(:event) }
  let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: event) }
  let(:auth_hash) do
    {
      "uid" => "108532000000000000001",
      "info" => {"name" => "Yusuke Nakamura", "image" => "https://lh3.example.invalid/a/yusuke.jpg"}
    }
  end

  before do
    stub_request(:get, "https://lh3.example.invalid/a/yusuke.jpg")
      .to_return(
        body: Rails.root.join("spec/assets/sample.png").binread,
        headers: {"Content-Type" => "image/png"}
      )
  end

  describe ".create_user_from_auth_hash" do
    it "creates the user, the provider and the profile" do
      expect {
        AuthenticationProviderGoogle.create_user_from_auth_hash(auth_hash)
      }.to change { AuthenticationProviderGoogle.count }.by(1)
        .and change { User.count }.by(1)
        .and change { Profile.count }.by(1)
    end

    # Google has no username, so there is nothing to derive a handle from.
    it "generates a handle and names the profile after the Google account" do
      user = AuthenticationProviderGoogle.create_user_from_auth_hash(auth_hash)

      expect(user.name).to match(/\Auser-[a-z0-9]{6}\z/)
      expect(user.profile.name).to eq "Yusuke Nakamura"
      expect(user.role).to eq "participant"
    end

    it "attaches the avatar from the auth hash" do
      user = AuthenticationProviderGoogle.create_user_from_auth_hash(auth_hash)

      expect(user.profile.images).to be_attached
    end

    it "marks published announcements unread" do
      FactoryBot.create(:announcement, :published, event: event)

      expect {
        AuthenticationProviderGoogle.create_user_from_auth_hash(auth_hash)
      }.to change { UnreadAnnouncement.count }.by(1)
    end

    # The organizer role comes from GitHub org membership, which says nothing
    # about a Google account.
    it "does not enqueue the role job" do
      expect {
        AuthenticationProviderGoogle.create_user_from_auth_hash(auth_hash)
      }.not_to have_enqueued_job(DetermineUserRoleJob)
    end
  end

  describe ".find_or_create_user_from_auth_hash" do
    it "returns the existing user when the uid is known" do
      existing = AuthenticationProviderGoogle.create_user_from_auth_hash(auth_hash)

      expect {
        expect(AuthenticationProviderGoogle.find_or_create_user_from_auth_hash(auth_hash)).to eq existing
      }.not_to change { User.count }
    end
  end
end
