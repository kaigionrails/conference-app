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
  };

  connect() {
    const video = document.getElementById("video");
    const currentHash = new URL(location.href).hash.replace("#", "");
    console.log("Current hash:", currentHash);

    // Get today's date
    const today = new Date();
    const day = today.getDate();

    if (day === 26) {
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

    // Apply video source if set
    if (this.videoSrc) {
      const videoElement = document.getElementById("video");
      const videoSrc = this.videoSrc;
      if (Hls.isSupported()) {
        const hls = new Hls();
        hls.loadSource(videoSrc);
        hls.attachMedia(videoElement);
      } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
        video.src = videoSrc;
      } else {
        console.log("HLS is not supported in this browser");
      }
      // videoElement.play(); // Uncomment if you want autoplay
    }
  }

  // updateCurrentTab({ params: { tab } }) {
  //   if (tab) {
  //     this.selectedTabValue = tab;
  //   }
  // }
}
