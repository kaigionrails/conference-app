require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { FactoryBot.create(:user) }

  describe "#mark_all_announcement_unread!" do
    context "there is no published announcement" do
      let(:event) { FactoryBot.create(:event) }
      let!(:announcements) { FactoryBot.create_list(:announcement, 3, event: event) }
      it "should not create any UnreadAnnouncement" do
        expect { user.mark_all_announcement_unread!(event) }.not_to change { UnreadAnnouncement.where(user: user).count }
      end
    end

    context "there is some published announcement" do
      let(:event) { FactoryBot.create(:event) }
      let!(:announcements_published) { FactoryBot.create_list(:announcement, 3, :published, event: event) }
      let!(:announcements_draft) { FactoryBot.create_list(:announcement, 2, event: event) }
      it "should create UnreadAnnouncement for number of published announcements" do
        expect { user.mark_all_announcement_unread!(event) }.to change { UnreadAnnouncement.where(user: user).count }.by(3)
      end
    end

    context "there is some published announcement but another event" do
      let(:event1) { FactoryBot.create(:event) }
      let(:event2) { FactoryBot.create(:event) }
      let!(:announcements_published) { FactoryBot.create_list(:announcement, 3, :published, event: event1) }
      it "should create UnreadAnnouncement for number of published announcements" do
        expect { user.mark_all_announcement_unread!(event2) }.not_to change { UnreadAnnouncement.where(user: user).count }
      end
    end
  end

  describe "destroy_talk_bookmark_with_reminder" do
    context "when there is no bookmark with given ID" do
      let(:id) { 42 }
      it "raises an error" do
        expect { user.destroy_talk_bookmark_with_reminder!(id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when there is a bookmark but no reminder" do
      let(:talk) { FactoryBot.create(:talk) }
      let!(:bookmark) { FactoryBot.create(:talk_bookmark, user: user, talk: talk) }
      let(:id) { bookmark.id }

      it "destroys the bookmark" do
        expect { user.destroy_talk_bookmark_with_reminder!(id) }.to change(TalkBookmark, :count).from(1).to(0)
      end
    end

    context "when there is a bookmark and a reminder" do
      let(:talk) { FactoryBot.create(:talk) }
      let!(:bookmark) { FactoryBot.create(:talk_bookmark, user: user, talk: talk) }
      let!(:reminder) { FactoryBot.create(:talk_reminder, user: user, talk: talk) }
      let(:id) { bookmark.id }

      it "destroys the bookmark and the reminder" do
        expect { user.destroy_talk_bookmark_with_reminder!(id) }.to change(TalkBookmark, :count).from(1).to(0)
          .and change(TalkReminder, :count).from(1).to(0)
      end
    end
  end

  describe "#have_unread_announcements?" do
    let(:event) { FactoryBot.create(:event) }
    let(:past_event) { FactoryBot.create(:event) }
    let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: event) }
    let!(:past_announcement) { FactoryBot.create(:announcement, :published, event: past_event) }
    let!(:ongoing_announcement) { FactoryBot.create(:announcement, :published, event: event) }
    before do
      UnreadAnnouncement.insert_all!(Announcement.published.where(event: past_event).all.pluck(:id).map { |ann_id| {user_id: user.id, announcement_id: ann_id} })
    end
    it { expect(user.have_unread_announcements?).to be_falsey }
  end

  describe "#unread_announcement_count" do
    let(:event) { FactoryBot.create(:event) }
    let(:past_event) { FactoryBot.create(:event) }
    let!(:ongoing_event) { FactoryBot.create(:ongoing_event, event: event) }
    let!(:past_announcement) { FactoryBot.create(:announcement, :published, event: past_event) }
    let!(:ongoing_announcement) { FactoryBot.create(:announcement, :published, event: event) }
    before do
      UnreadAnnouncement.insert_all!(Announcement.published.where(event: past_event).all.pluck(:id).map { |ann_id| {user_id: user.id, announcement_id: ann_id} })
    end
    it { expect(user.unread_announcement_count).to eq 0 }
  end
end
