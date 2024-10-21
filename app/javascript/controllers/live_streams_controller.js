import { Controller } from "@hotwired/stimulus";
import Hls from "hls.js";

export default class extends Controller {
  static values = { url: String };

  connect() {
    const videoElement = document.getElementById("video");
    const videoSrc = this.urlValue;
    if (Hls.isSupported()) {
      const hls = new Hls();
      hls.loadSource(videoSrc);
      hls.attachMedia(videoElement);
    } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
      video.src = videoSrc;
    }
    videoElement.play();
  }
}
