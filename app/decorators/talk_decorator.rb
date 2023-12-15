# frozen_string_literal: true

module TalkDecorator
  def sanitized_abstract
    markdown = Commonmarker.to_html(abstract)
    # Allow style attribute for fenced code blocks
    sanitizer.sanitize(markdown, attributes: %w[href style]).html_safe
  end

  def hashtagged_twitter_intent_url
    # https://developer.twitter.com/en/docs/twitter-for-websites/tweet-button/guides/web-intent
    tags = ["kaigionrails"]
    tags << "kaigionrailsA" if track && track == "Room A"
    tags << "kaigionrailsB" if track && track == "Room B"
    "https://twitter.com/intent/tweet?hashtags=#{tags.join(",")}"
  end

  private def sanitizer
    @sanitizer ||= Rails::Html::SafeListSanitizer.new
  end
end
