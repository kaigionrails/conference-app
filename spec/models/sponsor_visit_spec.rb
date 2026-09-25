require "rails_helper"

RSpec.describe SponsorVisit, type: :model do
  describe "validations" do
    subject(:sponsor_visit) { FactoryBot.build(:sponsor_visit, user: user, event: event) }

    let(:user) { FactoryBot.create(:user) }
    let(:event) { FactoryBot.create(:event) }

    it "is valid with a user, event, and sponsor key" do
      expect(sponsor_visit).to be_valid
    end

    it "requires a sponsor key" do
      sponsor_visit.sponsor_key = nil

      expect(sponsor_visit).not_to be_valid
    end

    it "does not allow duplicate visits for the same user, event, and sponsor" do
      FactoryBot.create(:sponsor_visit, user: sponsor_visit.user, event: sponsor_visit.event, sponsor_key: sponsor_visit.sponsor_key)

      expect(sponsor_visit).not_to be_valid
    end

    it "allows the same sponsor to be visited in a different event" do
      FactoryBot.create(:sponsor_visit, user: sponsor_visit.user, sponsor_key: sponsor_visit.sponsor_key)

      expect(sponsor_visit).to be_valid
    end
  end
end
