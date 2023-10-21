# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SpeakerDecorator do
  let(:speaker) { Speaker.new.extend SpeakerDecorator }

  describe "#sanitized_bio" do
    it "should return sanitized html" do
      speaker.bio = <<~MARKDOWN
        ## test
        [link](https://example.com)
        ```ruby
        puts "hello"
        ```
        <script>window.alert("hello")</script>

      MARKDOWN
      sanitized = speaker.sanitized_bio
      expect(sanitized.html_safe?).to eq true
      expect(sanitized).to include('<a href="https://example.com">link</a>')
      expect(sanitized).to include('puts')
      expect(sanitized).not_to include('background-color') # disable syntax highlighting
      expect(sanitized).not_to include("window.alert")
    end
  end
end
