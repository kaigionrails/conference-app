import { Controller } from "@hotwired/stimulus";
import Hls from "hls.js";

export default class extends Controller {
  static values = {
    selectedTab: { type: String, default: "red" },
    day1RedJa: { type: String, default: "" },
    day1BlueJa: { type: String, default: "" },
    day2RedJa: { type: String, default: "" },
    day2RedRaw: { type: String, default: "" },
    day2BlueJa: { type: String, default: "" },
    test: { type: String, default: "" },
    backstage: { type: Boolean, default: false },
  };

  static targets = ["cannotViewStreamInVenue", "shareToX"];

  connect() {
    const video = document.getElementById("video");
    let currentHash = new URL(location.href).hash.replace("#", "");
    if (currentHash == "") {currentHash = "red"}

    console.log("Current hash:", currentHash);

    // Get today's date
    const today = new Date();
    const day = today.getDate();

    if (day === 26 || day === 25) {
      if (currentHash === "red") {
        this.videoSrc = this.day1RedJaValue;
        this.selectedTabValue = "red";
      } else if (currentHash === "blue") {
        this.videoSrc = this.day1BlueJaValue;
        this.selectedTabValue = "blue";
      } else {
        console.warn("unknown day or tab value");
      }
    } else if (day === 27) {
      console.log("It's day 2!");
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
    if (this.selectedTabValue === "red") {
      video.classList.remove("border-[var(--color-2025-primary)]");
      video.classList.add("border-[var(--color-2025-danger)]");
    } else if (this.selectedTabValue === "blue") {
      video.classList.remove("border-[var(--color-2025-danger)]");
      video.classList.add("border-[var(--color-2025-primary)]");
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

  switchToRed() {
    const today = new Date();
    const day = today.getDate();
    if (this.hls == null) {
      this.hls = new Hls();
    }
    if (day === 26 || day === 25) {
      this.videoSrc = this.day1RedJaValue;
      this.selectedTabValue = "red";
    } else {
      console.warn("unknown day or tab value");
    }
    const video = document.getElementById("video");
    video.classList.remove("border-[var(--color-2025-primary)]");
    video.classList.add("border-[var(--color-2025-danger)]");
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

  switchToBlue() {
    const today = new Date();
    const day = today.getDate();
    if (this.hls == null) {
      this.hls = new Hls();
    }
    if (day === 26 || day === 25) {
      this.videoSrc = this.day1BlueJaValue;
      this.selectedTabValue = "blue";
    } else if (day === 27) {
      console.log("It's day 2!");
    } else {
      console.warn("unknown day or tab value");
    }
    const video = document.getElementById("video");
    video.classList.remove("border-[var(--color-2025-danger)]");
    video.classList.add("border-[var(--color-2025-primary)]");
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
    if(this.selectedTabValue === "red") {
      hashtags += ",kaigionrails_red"
    } else if(this.selectedTabValue === "blue") {
      hashtags += ",kaigionrails_blue"
    }
    this.shareToXTarget.href = `https://x.com/intent/tweet?hashtags=${encodeURIComponent(hashtags)}`;
  }

  webShare() {
    console.log("webShare");
    let hashtags = "#kaigionrails"
    if(this.selectedTabValue === "red") {
      hashtags += " #kaigionrails_red"
    } else if(this.selectedTabValue === "blue") {
      hashtags += " #kaigionrails_blue"
    }
    navigator.share({text: hashtags}).then();
  }
}
