module Social
  class BaseClient
    # media は Social::Attachment の配列。file と locale 解決済みの alt_text を使う
    # langs は Text.locale 由来。X / Mastodon は無視してよい
    # @rbs text: String
    # @rbs media: Array[Social::Attachment]
    # @rbs langs: Array[String]
    # @rbs idempotency_key: String?
    # @rbs return: Social::Result
    def post(text:, media: [], langs: [], idempotency_key: nil)
      raise NotImplementedError
    end

    # @rbs value: untyped
    # @rbs name: String
    # @rbs return: untyped
    private def require_credential!(value, name)
      raise PostError, "#{name} is not configured" if value.blank?

      value
    end
  end
end
