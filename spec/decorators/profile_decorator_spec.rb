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
end
