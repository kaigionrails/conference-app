import { Controller } from "@hotwired/stimulus";
import Hls from "hls.js";

export default class extends Controller {
  // Tabs, URL hashes and hashtags are named after the 2026 venues, Magenta Hall / Lime Hall.
  // The streams come from the Cloudflare live inputs named magenta-raw, magenta-interpretation,
  // lime-raw and lime-interpretation, which are used on every day of the event.
  static values = {
    selectedTab: { type: String, default: "magenta" },
    selectedAudio: { type: String, default: "raw" },
    magentaRaw: { type: String, default: "" },
    magentaInterpretation: { type: String, default: "" },
    limeRaw: { type: String, default: "" },
    limeInterpretation: { type: String, default: "" },
    test: { type: String, default: "" },
    backstage: { type: Boolean, default: false },
    yoyoTranslateMagentaHallUrl: { type: String, default: "" },
    yoyoTranslateLimeHallUrl: { type: String, default: "" },
  };

  static targets = ["cannotViewStreamInVenue", "shareToX", "yoyoTranslateLink", "hallTab", "audioButton"];

  connect() {
    let currentHash = new URL(location.href).hash.replace("#", "");
    if (!Object.hasOwn(this.streams(), currentHash)) {currentHash = "magenta"}

    console.log("Current hash:", currentHash);

    this.playStream(currentHash);
  }

  // Leaving the page with Turbo Drive does not stop hls.js, which keeps fetching the stream.
  disconnect() {
    this.hls?.destroy();
    this.hls = null;
  }

  // URL hash => the hall of the stream, its audio and its URL. #magenta and #lime are the venue sound.
  streams() {
    return {
      "magenta": { hall: "magenta", audio: "raw", url: this.magentaRawValue },
      "magenta-interpretation": { hall: "magenta", audio: "interpretation", url: this.magentaInterpretationValue },
      "lime": { hall: "lime", audio: "raw", url: this.limeRawValue },
      "lime-interpretation": { hall: "lime", audio: "interpretation", url: this.limeInterpretationValue },
      "test": { hall: "magenta", audio: null, url: this.testValue },
    };
  }

  // Switching the hall keeps the audio, and switching the audio keeps the hall.
  switchHall({ params: { hall } }) {
    this.switchTo(this.streamOf(hall, this.selectedAudioValue));
  }

  switchAudio({ params: { audio } }) {
    this.switchTo(this.streamOf(this.selectedTabValue, audio));
  }

  streamOf(hall, audio) {
    return audio === "interpretation" ? `${hall}-interpretation` : hall;
  }

  switchTo(stream) {
    if (stream === this.currentStream) {
      return;
    }
    // Keep history.state, where Turbo Drive puts what it needs to restore the page on going back.
    history.replaceState(history.state, "", `#${stream}`);
    this.playStream(stream);
  }

  playStream(stream) {
    const { hall, audio, url } = this.streams()[stream];
    const video = document.getElementById("video");
    this.currentStream = stream;
    this.selectedTabValue = hall;
    // #test has no audio, so the audio chosen before is kept.
    if (audio) {
      this.selectedAudioValue = audio;
    }
    this.updateSelection(hall, audio);

    // Stop the previous stream first, so a stream without URL leaves the video empty.
    this.hls?.destroy();
    this.hls = null;
    video.removeAttribute("src");
    video.load();

    if (url) {
      if (Hls.isSupported()) {
        this.hls = new Hls();
        this.hls.loadSource(url);
        this.hls.attachMedia(video);
      } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
        video.src = url;
      } else {
        console.log("HLS is not supported in this browser");
      }
    }
    if (hall === "magenta") {
      video.classList.remove("border-[var(--color-hall-lime)]");
      video.classList.add("border-[var(--color-hall-magenta)]");
    } else if (hall === "lime") {
      video.classList.remove("border-[var(--color-hall-magenta)]");
      video.classList.add("border-[var(--color-hall-lime)]");
    }
    this.updateShareTarget();
    this.updateYoyoTranslateLink();

    this.whereAmI().then((location) => {
      if (location === "at-venue") {
        this.cannotViewStreamInVenueTarget.classList.remove("hidden");
        this.hls?.destroy();
        this.hls = null;
        video.classList.add("hidden");
      } else {
        // do nothing
      }
    })
  }

  async whereAmI() {
    if (this.backstageValue) {
      return "not-at-venue";
    }
    const response = await fetch(
      "https://am-i-not-at-rubykaigi.s3.dualstack.ap-northeast-1.amazonaws.com/check",
      { method: "GET" }
    );
    if (response.ok) {
      return "not-at-venue";
    } else {
      return "at-venue";
    }
  }

  updateSelection(hall, audio) {
    this.hallTabTargets.forEach((tab) => {
      tab.setAttribute("aria-selected", String(tab.dataset.liveStreamsHallParam === hall));
    });
    this.audioButtonTargets.forEach((button) => {
      button.setAttribute("aria-pressed", String(button.dataset.liveStreamsAudioParam === audio));
    });
  }

  updateShareTarget() {
    let hashtags = "kaigionrails"
    if(this.selectedTabValue === "magenta") {
      hashtags += ",kaigionrails_magenta"
    } else if(this.selectedTabValue === "lime") {
      hashtags += ",kaigionrails_lime"
    }
    this.shareToXTarget.href = `https://x.com/intent/tweet?hashtags=${encodeURIComponent(hashtags)}`;
  }

  // Links to the subtitles of the selected hall, and hides the link while that hall has no URL.
  // The venue sound and the interpretation of a hall get the same subtitles.
  updateYoyoTranslateLink() {
    const url = this.selectedTabValue === "lime" ? this.yoyoTranslateLimeHallUrlValue : this.yoyoTranslateMagentaHallUrlValue;
    if (url) {
      this.yoyoTranslateLinkTarget.href = url;
      this.yoyoTranslateLinkTarget.classList.remove("hidden");
    } else {
      this.yoyoTranslateLinkTarget.classList.add("hidden");
    }
  }

  webShare() {
    console.log("webShare");
    let hashtags = "#kaigionrails"
    if(this.selectedTabValue === "magenta") {
      hashtags += " #kaigionrails_magenta"
    } else if(this.selectedTabValue === "lime") {
      hashtags += " #kaigionrails_lime"
    }
    navigator.share({text: hashtags}).then();
  }

  clipboard() {
    console.log("clipboard");
    let hashtags = "#kaigionrails"
    if(this.selectedTabValue === "magenta") {
      hashtags += " #kaigionrails_magenta"
    } else if(this.selectedTabValue === "lime") {
      hashtags += " #kaigionrails_lime"
    }
    navigator.clipboard.writeText(hashtags).then();
  }
}
