# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TalkDecorator do
  let(:talk) { Talk.new.extend TalkDecorator }

  describe "#sanitized_abstract" do
    it "should return sanitized html" do
      talk.abstract = <<~MARKDOWN
        ## test
        [link](https://example.com)
        ```ruby
        puts "hello"
        ```
        <script>window.alert("hello")</script>

      MARKDOWN
      sanitized = talk.sanitized_abstract
      expect(sanitized.html_safe?).to eq true
      expect(sanitized).to include('<a href="https://example.com">link</a>')
      expect(sanitized).to include('puts')
      expect(sanitized).to include('background-color') # syntax highlighting
      expect(sanitized).not_to include("window.alert")
    end
  end

  describe "#hashtagged_twitter_intent_url" do
    context "Room A" do
      before { talk.track = "Room A" }
      it "should return hashtagged intent url for room a (#kaigionrailsA)" do
        expect(talk.hashtagged_twitter_intent_url).to eq "https://twitter.com/intent/tweet?hashtags=kaigionrails,kaigionrailsA"
      end

    end
    context "Room B" do
      before { talk.track = "Room B" }
      it "should return hashtagged intent url for room b (#kaigionrailsB)" do
        expect(talk.hashtagged_twitter_intent_url).to eq "https://twitter.com/intent/tweet?hashtags=kaigionrails,kaigionrailsB"
      end
    end

    context "room not specified" do
      before { talk.track = nil }
      it "should return hashtagged intent url only #kaigionrails (#kaigionrails)" do
        expect(talk.hashtagged_twitter_intent_url).to eq "https://twitter.com/intent/tweet?hashtags=kaigionrails"
      end
    end
  end
end
