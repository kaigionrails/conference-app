require "rails_helper"

RSpec.describe "TalkBookmarks", type: :request do
  let!(:user) { FactoryBot.create(:user) }
  let!(:talk) { FactoryBot.create(:talk) }

  describe "POST /talk_bookmarks" do
    context "not logged in" do
      it "should fail" do
        post talk_bookmarks_path, params: {talk_bookmark: {talk_id: talk.id}}
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "logged in" do
      before { sign_in(user) }

      it "should success (and create reminder)" do
        post talk_bookmarks_path, params: {talk_bookmark: {talk_id: talk.id}}
        expect(response).to have_http_status(:ok)
        expect(TalkBookmark.where(user: user, talk: talk).count).to eq 1
        expect(TalkReminder.where(user: user, talk: talk).count).to eq 1
      end
    end
  end

  describe "DELETE /talk_bookmarks/:id" do
    let!(:talk_bookmark) { FactoryBot.create(:talk_bookmark, user: user, talk: talk) }
    let!(:talk_reminder) { FactoryBot.create(:talk_reminder, user: user, talk: talk) }
    before { sign_in(user) }

    it "should success (and remove reminder also)" do
      delete talk_bookmark_path(talk_bookmark.id)
      expect(response).to have_http_status(:ok)
      expect(TalkBookmark.where(user: user, talk: talk).count).to eq 0
      expect(TalkReminder.where(user: user, talk: talk).count).to eq 0
    end
  end
end
