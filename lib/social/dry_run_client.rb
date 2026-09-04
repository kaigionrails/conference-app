module Social
  # development 用。内側のクライアントを呼ばず偽の Result を返す
  class DryRunClient < BaseClient
    # @rbs inner: Social::BaseClient
    def initialize(inner)
      @inner = inner
    end

    def post(text:, media: [], langs: [], idempotency_key: nil)
      Result.new(
        remote_id: "dry-run-#{SecureRandom.hex(8)}",
        remote_url: "https://social.test/posts/dry-run"
      )
    end
  end
end
