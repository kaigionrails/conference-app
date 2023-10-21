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
end
