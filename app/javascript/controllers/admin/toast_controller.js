import { Controller } from "@hotwired/stimulus";

// トーストを duration ミリ秒後に自動で閉じる。duration が 0 ならクリックされるまで残す。
const FADE_OUT_MS = 300;

export default class extends Controller {
  static values = { duration: { type: Number, default: 5000 } };

  connect() {
    if (this.durationValue > 0) {
      this.timer = setTimeout(() => this.dismiss(), this.durationValue);
    }
  }

  disconnect() {
    clearTimeout(this.timer);
  }

  dismiss() {
    clearTimeout(this.timer);
    // opacity-0 クラスは ERB に現れず Tailwind が生成しないので style で消す
    this.element.style.opacity = "0";
    setTimeout(() => this.element.remove(), FADE_OUT_MS);
  }
}
