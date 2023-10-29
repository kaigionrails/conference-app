# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ProfileDecorator do
  let(:profile) { Profile.new.extend ProfileDecorator }

  describe "#sanitized_description" do
    it "should return sanitized html" do
      profile.description = <<~MARKDOWN
        ## test
        [link](https://example.com)
        ```ruby
        puts "hello"
        ```
        <script>window.alert("hello")</script>

      MARKDOWN
      sanitized = profile.sanitized_description
      expect(sanitized.html_safe?).to eq true
      expect(sanitized).to include('<a href="https://example.com">link</a>')
      expect(sanitized).to include('puts')
      expect(sanitized).not_to include('background-color') # disable syntax highlighting
      expect(sanitized).not_to include("window.alert")
    end
  end

  describe "#number_of_friends" do
    let(:user) { FactoryBot.create(:user, profile: profile) }
    let(:friends) { user.friends.preload(profile: { images_attachments: :blob }) }

    context "when friends are empty" do
      it "should return 0" do
        expect(profile.number_of_friends(friends)).to eq ''
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
        expect(profile.number_of_friends(friends)).to eq "(1人)"
      end
    end
  end
end
