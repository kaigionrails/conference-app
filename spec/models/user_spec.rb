require "rails_helper"

RSpec.describe User, type: :model do
  let(:user) { FactoryBot.create(:user) }

  describe ".name_starts_with" do
    context "with exact, prefix, and non-prefix matches" do
      let!(:exact) { FactoryBot.create(:user, name: "alice") }
      let!(:prefixed) { FactoryBot.create(:user, name: "alice_smith") }

      before do
        FactoryBot.create(:user, name: "malice")
        FactoryBot.create(:user, name: "bob")
      end

      it "matches names starting with the prefix, including an exact match" do
        expect(User.name_starts_with("alice")).to contain_exactly(exact, prefixed)
      end
    end

    context "with different letter cases" do
      let!(:matching) { FactoryBot.create(:user, name: "Alice") }

      it "ignores case" do
        expect(User.name_starts_with("ALi")).to contain_exactly(matching)
      end
    end

    context "with surrounding whitespace" do
      let!(:matching) { FactoryBot.create(:user, name: "alice") }

      it "strips surrounding whitespace from the prefix" do
        expect(User.name_starts_with("  ali  ")).to contain_exactly(matching)
      end
    end

    context "with a percent sign in the prefix" do
      let!(:matching) { FactoryBot.create(:user, name: "ali%ce") }

      before do
        FactoryBot.create(:user, name: "alice")
      end

      it "treats percent signs as literal characters" do
        expect(User.name_starts_with("ali%")).to contain_exactly(matching)
      end
    end

    context "with an underscore in the prefix" do
      let!(:matching) { FactoryBot.create(:user, name: "ali_ce") }

      before do
        FactoryBot.create(:user, name: "alice")
      end

      it "treats underscores as literal characters" do
        expect(User.name_starts_with("ali_")).to contain_exactly(matching)
      end
    end

    context "with an existing role condition" do
      let!(:matching) { FactoryBot.create(:user, name: "alice", role: :operator) }

      before do
        FactoryBot.create(:user, name: "alice_smith", role: :participant)
      end

      it "preserves other filtering conditions" do
        expect(User.where(role: :operator).name_starts_with("ali")).to contain_exactly(matching)
      end
    end
  end

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
