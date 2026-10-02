# frozen_string_literal: true

require "rails_helper"

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
      expect(sanitized).to include("puts")
      expect(sanitized).not_to include("background-color") # disable syntax highlighting
      expect(sanitized).not_to include("window.alert")
    end
  end

  describe "#icon_image and #thumb_image" do
    let(:profile) { FactoryBot.create(:profile).extend ProfileDecorator }

    it "return the variants of the first image" do
      profile.images.attach(io: Rails.root.join("spec/assets/sample.png").open, filename: "sample.png")
      expect(profile.icon_image.variation.transformations).to include(resize_to_limit: [50, 50])
      expect(profile.thumb_image.variation.transformations).to include(resize_to_limit: [240, 240])
    end

    it "return an image no variant can be made from as it is" do
      profile.images.attach(io: StringIO.new(%(<svg xmlns="http://www.w3.org/2000/svg"/>)), filename: "icon.svg", content_type: "image/svg+xml")
      expect(profile.icon_image).to eq(profile.images.first)
      expect(profile.thumb_image).to eq(profile.images.first)
    end

    it "return nil without an image" do
      expect(profile.icon_image).to be_nil
      expect(profile.thumb_image).to be_nil
    end
  end
end
