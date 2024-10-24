# frozen_string_literal: true

require "rails_helper"

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
      expect(sanitized).to include("puts")
      expect(sanitized).to include("background-color") # syntax highlighting
      expect(sanitized).not_to include("window.alert")
    end
  end

  describe "#hashtagged_twitter_intent_url" do
    context "Hall Red" do
      before { talk.track = "Hall Red" }
      it "should return hashtagged intent url for room red (#kaigionrails_red)" do
        expect(talk.hashtagged_twitter_intent_url).to eq "https://twitter.com/intent/tweet?hashtags=kaigionrails,kaigionrails_red"
      end
    end
    context "Hall Blue" do
      before { talk.track = "Hall Blue" }
      it "should return hashtagged intent url for room blue (#kaigionrails_blue)" do
        expect(talk.hashtagged_twitter_intent_url).to eq "https://twitter.com/intent/tweet?hashtags=kaigionrails,kaigionrails_blue"
      end
    end

    context "Room Red (wrong name)" do
      before { talk.track = "Room Red" }
      it "should return hashtagged intent url for room blue (#kaigionrails_blue)" do
        expect(talk.hashtagged_twitter_intent_url).to eq "https://twitter.com/intent/tweet?hashtags=kaigionrails,kaigionrails_red"
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
