# frozen_string_literal: true

require "rails_helper"

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
      expect(sanitized).to include("puts")
      expect(sanitized).not_to include("background-color") # disable syntax highlighting
      expect(sanitized).not_to include("window.alert")
    end
  end

  describe "#avatar_image_url" do
    let(:speaker) { FactoryBot.create(:speaker).extend SpeakerDecorator }

    it "returns the :thumb variant of the avatar" do
      speaker.avatar.attach(io: Rails.root.join("spec/assets/sample.png").open, filename: "avatar.png")
      expect(speaker.avatar_image_url.variation.transformations).to include(resize_to_limit: [192, 192])
    end

    it "returns an avatar no variant can be made from as it is" do
      speaker.avatar.attach(io: StringIO.new(%(<svg xmlns="http://www.w3.org/2000/svg"/>)), filename: "avatar.svg", content_type: "image/svg+xml")
      expect(speaker.avatar_image_url).to eq(speaker.avatar)
    end

    it "falls back to Gravatar without an avatar" do
      expect(speaker.avatar_image_url).to eq("https://www.gravatar.com/avatar/#{speaker.gravatar_hash}?s=100")
    end
  end
end
