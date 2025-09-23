import { Controller } from "@hotwired/stimulus";
import Hls from "hls.js";

export default class extends Controller {
  static values = {
    url: String,
    selectedTab: { type: String, default: "red" },
  };


  connect() {
    const currentHash = (new URL(location.href)).hash.replace("#", "");
    console.log("Current hash:", currentHash);
    // Hall Red or Hall Blue
    if (currentHash == "red" || currentHash == "blue") {
      this.selectedTabValue = currentHash
    }
    // this.updateCurrentTab();
    // const videoElement = document.getElementById("video");
    // const videoSrc = this.urlValue;
    // if (Hls.isSupported()) {
    //   const hls = new Hls();
    //   hls.loadSource(videoSrc);
    //   hls.attachMedia(videoElement);
    // } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
    //   video.src = videoSrc;
    // }
    // videoElement.play();
  }

  updateCurrentTab({ params: { tab } }) {
    if (tab) {
      this.selectedTabValue = tab;
    }
  }
}
