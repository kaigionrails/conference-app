require 'rails_helper'

RSpec.describe "Admin::Talks", type: :request do
  before do
    talk = FactoryBot.create(:talk, title: "sample talk")
    speaker = FactoryBot.create(:speaker)
    talk.speakers << speaker
  end

  describe "GET /index" do
    context "user is not an organizer" do
      let(:user) { FactoryBot.create(:user, role: :participant) }
      before { sign_in(user) }
      it "redirect to root path" do
        get admin_talks_path
        expect(response).to redirect_to(root_path)
      end
    end

    context "user is an organizer" do
      let(:user) { FactoryBot.create(:user, role: :organizer) }
      before { sign_in(user) }
      it "shows users list table" do
        get admin_talks_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Talks")
        expect(response.body).to include("sample talk")
      end
    end
  end

  describe "GET /talks/:id" do
    let(:user) { FactoryBot.create(:user, role: :organizer) }
    before { sign_in(user) }
    let(:target_talk) { Talk.find_by!(title: "sample talk") }
    it "shows specific talk info" do
      get admin_talk_path(target_talk)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("sample talk")
    end
  end

  describe "PATCH /talks/:id" do
    let(:user) { FactoryBot.create(:user, role: :organizer) }
    before { sign_in(user) }
    let(:target_talk) { Talk.find_by!(title: "sample talk") }
    it "should update success" do
      updated_start_at = Time.zone.parse("2023-10-20 11:00:00")
      update_params = {
        talk: {
          title: "sample talk (special)",
          abstract: "super awesome talk!",
          start_at_date: updated_start_at.strftime("%Y/%m/%d"), # 2023/10/20
          start_at_time: updated_start_at.strftime("%H:%M"), # 11:00
          duration_minutes: "10",
          track: "room 100",
        }
      }
      patch admin_talk_path(target_talk), params: update_params
      expect(response).to have_http_status(:redirect)
      target_talk.reload
      expect(target_talk.title).to eq("sample talk (special)")
      expect(target_talk.abstract).to eq("super awesome talk!")
      expect(target_talk.duration_minutes).to eq(10)
      expect(target_talk.start_at).to eq(Time.zone.parse("2023-10-20 02:00:00 +0000")) # saved as UTC
      expect(target_talk.track).to eq("room 100")
    end
  end
end
