module Social
  # X の weighted character count。全プラットフォーム共通の本文上限に使う。
  # ルールは https://docs.x.com/fundamentals/counting-characters に従う:
  # - デフォルト重み 2
  # - 基本ラテン / Latin-1 / 一部の約物は重み 1
  # - URL は t.co 相当で 23
  # - CJK・絵文字は 2 (日本語だけなら 280 / 2 = 140 字)
  class XWeightedLength
    LIMIT = 280
    URL_WEIGHT = 23
    # twitter-text の config v3 相当
    WEIGHT_ONE_RANGES = [0x0000..0x10FF, 0x2000..0x200D, 0x2010..0x201F, 0x2032..0x2037].freeze
    URL_PATTERN = %r{(?:https?://|www\.)[^\s<>"'）」】]+}i
    EMOJI_PATTERN = /\p{Extended_Pictographic}|\p{Emoji_Presentation}/

    # @rbs text: String?
    def initialize(text)
      @text = text.to_s.unicode_normalize(:nfc)
    end

    # @rbs return: Integer
    def to_i
      urls = @text.scan(URL_PATTERN)
      rest = @text.gsub(URL_PATTERN, "")
      urls.size * URL_WEIGHT + rest.grapheme_clusters.sum { |cluster| weight_of(cluster) }
    end

    # @rbs return: bool
    def valid?
      to_i <= LIMIT
    end

    # @rbs cluster: String
    # @rbs return: Integer
    private def weight_of(cluster)
      return 2 if EMOJI_PATTERN.match?(cluster)

      cluster.each_codepoint.sum { |cp| (WEIGHT_ONE_RANGES.any? { |r| r.cover?(cp) }) ? 1 : 2 }
    end
  end
end
