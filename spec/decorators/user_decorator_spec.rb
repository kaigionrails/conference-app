# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserDecorator do
  let(:user) { FactoryBot.create(:user).extend UserDecorator }

  describe "#number_of_friends" do
    context "when event is not given" do
      context "when friends are empty" do
        it "should return 0" do
          expect(user.number_of_friends).to eq 0
        end
      end

      context "when friends are not empty" do
        let(:event) { FactoryBot.create(:event) }
        let(:friend) { FactoryBot.create(:user) }

        before do
          ProfileExchange.find_or_create_by!(event: event, user: user, friend: friend)
          ProfileExchange.find_or_create_by!(event: event, user: friend, friend: user)
        end

        it "should return the number of friends" do
          expect(user.number_of_friends).to eq 1
        end
      end
    end

    context "when event is given" do
      let(:event1) { FactoryBot.create(:event) }
      let(:event2) { FactoryBot.create(:event) }
      let(:event3) { FactoryBot.create(:event) }
      let(:friend1) { FactoryBot.create(:user) }
      let(:friend2) { FactoryBot.create(:user) }
      let(:friend3) { FactoryBot.create(:user) }

      before do
        ProfileExchange.find_or_create_by!(event: event1, user: user, friend: friend1)
        ProfileExchange.find_or_create_by!(event: event1, user: friend1, friend: user)
        ProfileExchange.find_or_create_by!(event: event1, user: user, friend: friend2)
        ProfileExchange.find_or_create_by!(event: event1, user: friend2, friend: user)

        ProfileExchange.find_or_create_by!(event: event2, user: user, friend: friend1)
        ProfileExchange.find_or_create_by!(event: event2, user: friend1, friend: user)
        ProfileExchange.find_or_create_by!(event: event2, user: user, friend: friend2)
        ProfileExchange.find_or_create_by!(event: event2, user: friend2, friend: user)
        ProfileExchange.find_or_create_by!(event: event2, user: user, friend: friend3)
        ProfileExchange.find_or_create_by!(event: event2, user: friend3, friend: user)
      end

      context "when friends are empty" do
        it "should return 0" do
          expect(user.number_of_friends(event3)).to eq 0
        end
      end

      context "when friends are not empty" do
        it "should return the number of friends" do
          expect(user.number_of_friends(event1)).to eq 2
          expect(user.number_of_friends(event2)).to eq 3
        end
      end
    end
  end
end
