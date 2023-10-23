require 'rails_helper'

RSpec.describe Talk, type: :model do
  let(:talk) { FactoryBot.create(:talk) }

  describe "#bookmarked_by?" do
    context "user is nil" do
      it "should return false" do
        expect(talk.bookmarked_by?(nil)).to eq false
      end
    end

    context "user is not bookmarked the talk" do
      let(:user) { FactoryBot.create(:user) }
      it "should return false" do
        expect(talk.bookmarked_by?(user)).to eq false
      end
    end

    context "user bookmarked the talk" do
      let(:user) { FactoryBot.create(:user) }
      let!(:bookmark) { FactoryBot.create(:talk_bookmark, user: user, talk: talk) }
      it "should return false" do
        expect(talk.bookmarked_by?(user)).to eq true
      end
    end
  end

  describe "#bookmark_by" do
    context "user is nil" do
      it "should return nil" do
        expect(talk.bookmark_by(nil)).to eq nil
      end
    end

    context "user is not bookmarked the talk" do
      let(:user) { FactoryBot.create(:user) }
      it "should return nil" do
        expect(talk.bookmark_by(nil)).to eq nil
      end
    end

    context "user bookmarked the talk" do
      let(:user) { FactoryBot.create(:user) }
      let!(:bookmark) { FactoryBot.create(:talk_bookmark, user: user, talk: talk) }
      it "should return false" do
        expect(talk.bookmark_by(user)).to eq bookmark
      end
    end
  end
end
