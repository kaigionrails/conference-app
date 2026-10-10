import { Controller } from "@hotwired/stimulus";
import Hls from "hls.js";

// While the live input is not broadcasting, load it again every 10 seconds for up to 30 minutes.
const RETRY_INTERVAL_MS = 10000;
const RETRY_LIMIT = 180;

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

  static targets = ["cannotViewStreamInVenue", "shareToX", "yoyoTranslateLink", "hallTab", "audioButton", "unmuteButton"];

  connect() {
    // Going back with Turbo Drive renders the page from its cache, which can still show the button.
    this.mutedByBrowser = false;
    this.unmuteButtonTarget.classList.add("hidden");
    this.retryCount = 0;
    this.atVenue = false;

    let currentHash = new URL(location.href).hash.replace("#", "");
    if (!Object.hasOwn(this.streams(), currentHash)) {currentHash = "magenta"}

    console.log("Current hash:", currentHash);

    this.playStream(currentHash);
  }

  // Leaving the page with Turbo Drive does not stop hls.js, which keeps fetching the stream.
  disconnect() {
    clearTimeout(this.retryTimer);
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

    // The retries of the previous stream must not load it over this one.
    clearTimeout(this.retryTimer);
    this.retryCount = 0;
    this.loadStream(video, url);
    this.updateUnmuteButton();
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
        this.atVenue = true;
        clearTimeout(this.retryTimer);
        this.cannotViewStreamInVenueTarget.classList.remove("hidden");
        // Also remove the src, which a browser playing HLS natively keeps fetching even when hidden.
        this.hls?.destroy();
        this.hls = null;
        video.removeAttribute("src");
        video.load();
        video.classList.add("hidden");
        this.unmuteButtonTarget.classList.add("hidden");
      } else {
        // do nothing
      }
    })
  }

  // Stop the previous stream first, so a stream without URL leaves the video empty.
  loadStream(video, url) {
    this.hls?.destroy();
    this.hls = null;
    video.removeAttribute("src");
    video.load();
    if (!url) return;

    if (Hls.isSupported()) {
      this.hls = new Hls();
      this.hls.loadSource(url);
      this.hls.attachMedia(video);
      this.hls.on(Hls.Events.MANIFEST_PARSED, () => {
        this.retryCount = 0;
        this.startPlayback(video);
      });
      this.hls.on(Hls.Events.ERROR, (_event, data) => {
        if (data.fatal) this.scheduleRetry(video, url);
      });
    } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
      video.src = url;
      this.startPlayback(video);
    } else {
      console.log("HLS is not supported in this browser");
    }
  }

  // The live input answers 204 with no playlist while it is not broadcasting.
  // Load it again every 10 seconds, so that the stream starts without a reload, for up to 30 minutes.
  scheduleRetry(video, url) {
    this.hls?.destroy();
    this.hls = null;
    if (this.atVenue) return;
    if (this.retryCount >= RETRY_LIMIT) {
      console.warn("Gave up retrying the stream; reload the page to try again");
      return;
    }
    this.retryCount += 1;
    console.warn(`Retrying the stream in ${RETRY_INTERVAL_MS / 1000} seconds (${this.retryCount}/${RETRY_LIMIT})`);
    this.retryTimer = setTimeout(() => {
      this.retryTimer = null;
      this.loadStream(video, url);
    }, RETRY_INTERVAL_MS);
  }

  // Browsers block autoplay with sound until the viewer interacts with the page, as on a reload.
  // Then play it muted, and show the button to unmute.
  startPlayback(video) {
    video.play().catch((error) => {
      // AbortError comes when the stream is switched before it starts playing.
      if (error.name !== "NotAllowedError") return;
      video.muted = true;
      this.mutedByBrowser = true;
      this.updateUnmuteButton();
      video.play().catch(() => {});
    });
  }

  unmute() {
    const video = document.getElementById("video");
    video.muted = false;
    if (video.paused) {
      video.play().catch(() => {});
    }
  }

  // Unmuting with the button or the controls of the video comes here.
  volumeChanged() {
    if (!document.getElementById("video").muted) {
      this.mutedByBrowser = false;
      this.updateUnmuteButton();
    }
  }

  // Shown only while the browser keeps the video muted, and not over a stream without URL.
  // Viewers who mute the video themselves do not see it.
  updateUnmuteButton() {
    const visible = this.mutedByBrowser && Boolean(this.streams()[this.currentStream].url);
    this.unmuteButtonTarget.classList.toggle("hidden", !visible);
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
