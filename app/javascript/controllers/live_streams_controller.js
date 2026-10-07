import { Controller } from "@hotwired/stimulus";
import Hls from "hls.js";

export default class extends Controller {
  // Tabs, URL hashes and hashtags are named after the 2026 venues, Magenta Hall / Lime Hall.
  // The streams come from the Cloudflare live inputs named day1-magenta-ja and so on.
  static values = {
    selectedTab: { type: String, default: "magenta" },
    day1MagentaJa: { type: String, default: "" },
    day1LimeJa: { type: String, default: "" },
    day2MagentaJa: { type: String, default: "" },
    day2MagentaRaw: { type: String, default: "" },
    day2LimeJa: { type: String, default: "" },
    test: { type: String, default: "" },
    backstage: { type: Boolean, default: false },
  };

  static targets = ["cannotViewStreamInVenue", "shareToX"];

  connect() {
    const video = document.getElementById("video");
    let currentHash = new URL(location.href).hash.replace("#", "");
    if (currentHash == "") {currentHash = "magenta"}

    console.log("Current hash:", currentHash);

    // Get today's date
    const today = new Date();
    const day = today.getDate();

    if (day === 26 || day === 25) {
      if (currentHash === "magenta") {
        this.videoSrc = this.day1MagentaJaValue;
        this.selectedTabValue = "magenta";
      } else if (currentHash === "lime") {
        this.videoSrc = this.day1LimeJaValue;
        this.selectedTabValue = "lime";
      } else {
        console.warn("unknown day or tab value");
      }
    } else if (day === 27) {
      if (currentHash === "magenta") {
        this.videoSrc = this.day2MagentaJaValue;
        this.selectedTabValue = "magenta";
      } else if (currentHash === "lime") {
        this.videoSrc = this.day2LimeJaValue;
        this.selectedTabValue = "lime";
      } else {
        console.warn("unknown day or tab value");
      }
    } else {
      console.warn("unknown day or tab value");
    }

    if (currentHash === "test") {
      this.videoSrc = this.testValue;
    }
    // temp
    // this.videoSrc = this.testValue;

    // Apply video source if set
    const videoSrc = this.videoSrc;
    if (this.videoSrc) {
      if (Hls.isSupported()) {
        this.hls = new Hls();
        this.hls.loadSource(videoSrc);
        this.hls.attachMedia(video);
      } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
        video.src = videoSrc;
      } else {
        console.log("HLS is not supported in this browser");
      }
      // videoElement.play(); // Uncomment if you want autoplay
    }
    if (this.selectedTabValue === "magenta") {
      video.classList.remove("border-[var(--color-hall-lime)]");
      video.classList.add("border-[var(--color-hall-magenta)]");
    } else if (this.selectedTabValue === "lime") {
      video.classList.remove("border-[var(--color-hall-magenta)]");
      video.classList.add("border-[var(--color-hall-lime)]");
    }
    this.updateShareTarget();
    this.whereAmI().then((location) => {
      if (location === "at-venue") {
        this.cannotViewStreamInVenueTarget.classList.remove("hidden");
        this.hls?.destroy();
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

  switchToMagenta() {
    const today = new Date();
    const day = today.getDate();
    if (this.hls == null) {
      this.hls = new Hls();
    }
    if (day === 26 || day === 25) {
      this.videoSrc = this.day1MagentaJaValue;
      this.selectedTabValue = "magenta";
    } else if (day === 27) {
      this.videoSrc = this.day2MagentaJaValue;
      this.selectedTabValue = "magenta";
    }
    const video = document.getElementById("video");
    video.classList.remove("border-[var(--color-hall-lime)]");
    video.classList.add("border-[var(--color-hall-magenta)]");
    this.hls.loadSource(this.videoSrc);
    this.hls.attachMedia(video);
    this.updateShareTarget();

    this.whereAmI().then((location) => {
      if (location === "at-venue") {
        this.cannotViewStreamInVenueTarget.classList.remove("hidden");
        this.hls?.destroy();
        video.classList.add("hidden");
      } else {
        // do nothing
      }
    })
  }

  switchToMagentaRaw() {
    const today = new Date();
    const day = today.getDate();
    if (this.hls == null) {
      this.hls = new Hls();
    }
    if (day === 26 || day === 25) {
      this.videoSrc = this.day1MagentaJaValue;
      this.selectedTabValue = "magenta";
    } else if (day === 27) {
      this.videoSrc = this.day2MagentaRawValue;
      this.selectedTabValue = "magenta";
    }
    const video = document.getElementById("video");
    video.classList.remove("border-[var(--color-hall-lime)]");
    video.classList.add("border-[var(--color-hall-magenta)]");
    this.hls.loadSource(this.videoSrc);
    this.hls.attachMedia(video);
    this.updateShareTarget();

    this.whereAmI().then((location) => {
      if (location === "at-venue") {
        this.cannotViewStreamInVenueTarget.classList.remove("hidden");
        this.hls?.destroy();
        video.classList.add("hidden");
      } else {
        // do nothing
      }
    })
  }

  switchToLime() {
    const today = new Date();
    const day = today.getDate();
    if (this.hls == null) {
      this.hls = new Hls();
    }
    if (day === 26 || day === 25) {
      this.videoSrc = this.day1LimeJaValue;
      this.selectedTabValue = "lime";
    } else if (day === 27) {
      this.videoSrc = this.day2LimeJaValue;
      this.selectedTabValue = "lime";
    } else {
      console.warn("unknown day or tab value");
    }
    const video = document.getElementById("video");
    video.classList.remove("border-[var(--color-hall-magenta)]");
    video.classList.add("border-[var(--color-hall-lime)]");
    this.hls.loadSource(this.videoSrc);
    this.hls.attachMedia(video);
    this.updateShareTarget();

    this.whereAmI().then((location) => {
      if (location === "at-venue") {
        this.cannotViewStreamInVenueTarget.classList.remove("hidden");
        this.hls?.destroy();
        video.classList.add("hidden");
      } else {
        // do nothing
      }
    })
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
