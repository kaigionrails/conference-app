import { Controller } from "@hotwired/stimulus";
import QRCode from "qrcode";
import * as jose from "jose";
import PhotoSwipe from "photoswipe";
import PhotoSwipeLightbox from "photoswipe/lightbox";

export default class extends Controller {
  static targets = [
    "qrcodeImg",
    "profileImg",
    "showQrcode",
    "hideQrcode",
    "submitButton",
  ];
  static values = {
    baseUrl: String,
    username: String,
    submittingLabel: String,
  };

  connect() {
    console.info("profiles controller");
    this.setupLightbox();
  }

  // The profile form is sent without Turbo, so data-turbo-submits-with does
  // nothing there. This does its job instead: the images upload before the
  // next page comes, which takes seconds from a phone, and the form must not be
  // sent twice meanwhile.
  showSubmitting() {
    const button = this.submitButtonTarget;
    this.submitButtonContent = Array.from(button.childNodes);
    button.disabled = true;
    button.textContent = this.submittingLabelValue;
  }

  // Going back to the form can restore it from the back/forward cache as it
  // was left, with the button still disabled.
  restoreSubmit(event) {
    if (!event.persisted || this.submitButtonContent === undefined) return;

    const button = this.submitButtonTarget;
    button.replaceChildren(...this.submitButtonContent);
    button.disabled = false;
    this.submitButtonContent = undefined;
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
