import { Controller } from "@hotwired/stimulus";

// X の weighted length を概算するクライアント側カウンタ。サーバ側 (Social::XWeightedLength) が真の正。
const LIMIT = 280;
const URL_WEIGHT = 23;
const URL_PATTERN = /(?:https?:\/\/|www\.)[^\s<>"'）」】]+/gi;
const EMOJI_PATTERN = /\p{Extended_Pictographic}|\p{Emoji_Presentation}/u;
const WEIGHT_ONE_RANGES = [
  [0x0000, 0x10ff],
  [0x2000, 0x200d],
  [0x2010, 0x201f],
  [0x2032, 0x2037],
];
const segmenter = typeof Intl !== "undefined" && Intl.Segmenter ? new Intl.Segmenter(undefined, { granularity: "grapheme" }) : null;

export function weightedLength(text) {
  const normalized = (text || "").normalize("NFC");
  const urls = normalized.match(URL_PATTERN) || [];
  const rest = normalized.replace(URL_PATTERN, "");
  const clusters = segmenter ? Array.from(segmenter.segment(rest), (s) => s.segment) : Array.from(rest);
  let total = urls.length * URL_WEIGHT;
  for (const cluster of clusters) {
    if (EMOJI_PATTERN.test(cluster)) {
      total += 2;
      continue;
    }
    for (const ch of cluster) {
      const cp = ch.codePointAt(0);
      total += WEIGHT_ONE_RANGES.some(([lo, hi]) => cp >= lo && cp <= hi) ? 1 : 2;
    }
  }
  return total;
}

export default class extends Controller {
  static targets = ["body", "count", "mediaCount", "hashtagWarning", "mentionWarning"];
  static values = { maxMedia: Number, hashtag: String };

  connect() {
    this.bodyTargets.forEach((textarea) => this.render(textarea));
  }

  updateCount(event) {
    this.render(event.target);
  }

  render(textarea) {
    const index = this.bodyTargets.indexOf(textarea);
    const counter = this.countTargets[index];
    if (counter) {
      const length = weightedLength(textarea.value);
      counter.textContent = length;
      counter.classList.toggle("text-red-600", length > LIMIT);
      counter.classList.toggle("font-bold", length > LIMIT);
    }
    const warning = this.hashtagWarningTargets[index];
    if (warning && this.hashtagValue) {
      const body = textarea.value.trim();
      // 前後が空白・改行・文字列端でないとハッシュタグとして成立しない (サーバ側の
      // SocialAnnouncement::RECOMMENDED_HASHTAG_PATTERN と同じ判定)
      const escaped = this.hashtagValue.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
      const pattern = new RegExp(`(?:^|\\s)${escaped}(?:\\s|$)`, "i");
      warning.hidden = body === "" || pattern.test(body);
    }
    const mentionWarning = this.mentionWarningTargets[index];
    if (mentionWarning) {
      // SocialAnnouncement::MENTION_PATTERN と同じ判定
      mentionWarning.hidden = !/(?:^|\s)@\w/.test(textarea.value);
    }
  }
}
