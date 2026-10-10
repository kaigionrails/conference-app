require "rails_helper"

RSpec.describe "Admin::Speakers", type: :request do
  let(:talk) { FactoryBot.create(:talk, title: "sample talk") }
  let(:speaker) { FactoryBot.create(:speaker) }

  before do
    talk.speakers << speaker
  end

  context "user is not an organizer" do
    let(:user) { FactoryBot.create(:user, role: :participant) }
    before { sign_in(user) }

    describe "GET /admin/talks/:talk_id/speakers/:id/edit" do
      it "redirects to root path" do
        get edit_admin_talk_speaker_path(talk, speaker)
        expect(response).to redirect_to(root_path)
      end
    end

    describe "PATCH /admin/talks/:talk_id/speakers/:id" do
      it "redirects to root path without updating the speaker" do
        expect {
          patch admin_talk_speaker_path(talk, speaker), params: {speaker: {name: "Yukihiro Matsumoto"}}
        }.not_to change { speaker.reload.name }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  context "user is an organizer" do
    let(:user) { FactoryBot.create(:user, role: :organizer) }
    before { sign_in(user) }

    describe "GET /admin/talks/:talk_id/speakers/:id/edit" do
      it "shows the form of the speaker" do
        get edit_admin_talk_speaker_path(talk, speaker)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("David Heinemeier Hansson")
        expect(response.body).to include("dhh")
      end

      it "does not show a speaker of another talk" do
        other_speaker = FactoryBot.create(:speaker, name: "Yukihiro Matsumoto", slug: "matz", github_username: "matz")
        FactoryBot.create(:talk, title: "another talk").speakers << other_speaker

        get edit_admin_talk_speaker_path(talk, other_speaker)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /admin/talks/:talk_id/speakers/:id" do
      it "updates the speaker and goes back to the talk" do
        patch admin_talk_speaker_path(talk, speaker), params: {
          speaker: {
            name: "DHH",
            github_username: "dhh-new",
            gravatar_hash: "0123456789abcdef0123456789abcdef",
            bio: "Creator of Ruby on Rails."
          }
        }
        expect(response).to redirect_to(admin_talk_path(talk))
        expect(speaker.reload).to have_attributes(
          name: "DHH",
          github_username: "dhh-new",
          gravatar_hash: "0123456789abcdef0123456789abcdef",
          bio: "Creator of Ruby on Rails."
        )

        follow_redirect!
        expect(response.body).to include("Update succeeded")
      end

      it "renders the form again with 422 when the name is blank" do
        expect {
          patch admin_talk_speaker_path(talk, speaker), params: {speaker: {name: ""}}
        }.not_to change { speaker.reload.name }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Update failed")

        get admin_talks_path
        expect(response.body).not_to include("Update failed")
      end

      it "does not update a speaker of another talk" do
        other_speaker = FactoryBot.create(:speaker, name: "Yukihiro Matsumoto", slug: "matz", github_username: "matz")
        FactoryBot.create(:talk, title: "another talk").speakers << other_speaker

        expect {
          patch admin_talk_speaker_path(talk, other_speaker), params: {speaker: {name: "Matz"}}
        }.not_to change { other_speaker.reload.name }
        expect(response).to have_http_status(:not_found)
      end

      it "ignores the slug" do
        expect {
          patch admin_talk_speaker_path(talk, speaker), params: {speaker: {name: "DHH", slug: "david"}}
        }.not_to change { speaker.reload.slug }
        expect(speaker.name).to eq("DHH")
      end
    end
  end
end
