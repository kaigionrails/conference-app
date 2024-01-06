# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserDecorator do
  let(:user) { FactoryBot.create(:user).extend UserDecorator }

  describe "#number_of_friends" do
    context "when friends are empty" do
      it "should return 0" do
        expect(user.number_of_friends).to eq ""
      end
    end

    context "when friends are not empty" do
      let(:event) { FactoryBot.create(:event) }
      let(:friend) { FactoryBot.create(:user) }

      before do
        ProfileExchange.find_or_create_by!(event: event, user: user, friend: friend)
        ProfileExchange.find_or_create_by!(event: event, user: friend, friend: user)
      end

      it "should return the number of friends in `(n人)` format" do
        expect(user.number_of_friends).to eq "(1人)"
      end
    end
  end
end
