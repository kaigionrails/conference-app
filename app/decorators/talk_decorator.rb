# frozen_string_literal: true

module TalkDecorator
  def sanitized_abstract
    markdown = Commonmarker.to_html(abstract)
    # Allow style attribute for fenced code blocks
    sanitizer.sanitize(markdown, attributes: %w[href style]).html_safe
  end

  def hashtagged_twitter_intent_url
    # https://developer.x.com/en/docs/x-for-websites/tweet-button/guides/web-intent
    tags = ["kaigionrails"]
    tags << "kaigionrails_red" if track && track == "Room Red"
    tags << "kaigionrails_blue" if track && track == "Room Blue"
    "https://twitter.com/intent/tweet?hashtags=#{tags.join(",")}"
  end

  private def sanitizer
    @sanitizer ||= Rails::Html::SafeListSanitizer.new
  end
end
