require "rails_helper"

RSpec.describe Event, type: :model do
  describe "#community_profile_exchange_count" do
    let(:event) { FactoryBot.create(:event) }
    let(:other_event) { FactoryBot.create(:event) }
    let(:users) { FactoryBot.create_list(:user, 4) }

    def exchange(event, user1, user2)
      ProfileExchange.create!(event:, user: user1, friend: user2)
      ProfileExchange.create!(event:, user: user2, friend: user1)
    end

    it "counts people, each exchange being stored in both directions" do
      exchange(event, users[0], users[1])
      exchange(event, users[0], users[2])

      expect(event.community_profile_exchange_count).to eq(3)
    end

    it "leaves out exchanges at other events" do
      exchange(event, users[0], users[1])
      exchange(other_event, users[2], users[3])

      expect(event.community_profile_exchange_count).to eq(2)
    end

    it "is zero before anyone has exchanged" do
      expect(event.community_profile_exchange_count).to eq(0)
    end
  end
end
