import { Controller } from "@hotwired/stimulus";
import QRCode from "qrcode";
import * as jose from "jose";
import PhotoSwipe from "photoswipe";
import PhotoSwipeLightbox from "photoswipe/lightbox";

export default class extends Controller {
  static targets = ["qrcodeImg", "profileImg", "showQrcode", "hideQrcode"];
  static values = {
    baseUrl: String,
    username: String,
  };

  connect() {
    console.info("profiles controller");
    this.setupLightbox();
  }

  async showQrcode() {
    // Sure, unsecure! but enough ;)
    const unsecuredJwt = new jose.UnsecuredJWT({})
      .setIssuedAt()
      .setIssuer(this.usernameValue)
      .setExpirationTime("3mins")
      .encode();
    const profileUrl = new URL(
      `@${this.usernameValue}?token=${unsecuredJwt}`,
      this.baseUrlValue
    ).toString();
    const dataUrl = await QRCode.toDataURL(profileUrl, {
      width: 600,
    });
    this.qrcodeImgTarget.setAttribute("src", dataUrl);
    this.qrcodeImgTarget.classList.remove("hidden");
    this.qrcodeImgTarget.classList.add("absolute", "top-0");
    this.showQrcodeTarget.classList.add("hidden");
    this.hideQrcodeTarget.classList.remove("hidden");
  }
  async hideQrcode() {
    this.hideQrcodeTarget.classList.add("hidden");
    this.qrcodeImgTarget.classList.add("hidden");
    this.showQrcodeTarget.classList.remove("hidden");
  }

  setupLightbox() {
    const lightbox = new PhotoSwipeLightbox({
      gallery: "#lightbox",
      children: "a",
      initialZoomLevel: "fit",
      pswpModule: PhotoSwipe,
    });
    lightbox.init();
  }
}
