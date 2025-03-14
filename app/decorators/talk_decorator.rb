# frozen_string_literal: true

# @rbs module-self Talk
module TalkDecorator
  def sanitized_abstract
    markdown = Commonmarker.to_html(abstract)
    # Allow style attribute for fenced code blocks
    sanitizer.sanitize(markdown, attributes: %w[href style]).html_safe
  end

  def hashtagged_twitter_intent_url
    # https://developer.x.com/en/docs/x-for-websites/tweet-button/guides/web-intent
    tags = ["kaigionrails"]
    tags << "kaigionrails_red" if track&.include?("Red")
    tags << "kaigionrails_blue" if track&.include?("Blue")
    "https://twitter.com/intent/tweet?hashtags=#{tags.join(",")}"
  end

  # @rbs @sanitizer: Rails::Html::SafeListSanitizer

  private def sanitizer
    @sanitizer ||= Rails::Html::SafeListSanitizer.new
  end
end
