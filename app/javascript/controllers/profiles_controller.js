import { Controller } from "@hotwired/stimulus";
import QRCode from "qrcode";

export default class extends Controller {
  static targets = ["qrcodeImg", "profileImg", "showQrcode", "hideQrcode"];
  static values = {
    baseUrl: String,
    username: String,
  };

  connect() {
    console.info("profiles controller");
  }

  addProfileImageField(event, className) {
    event.preventDefault();
    const insertTargetElement = document.getElementById("profile-image-fields");
    let fieldElement = document.createElement("input");
    fieldElement.setAttribute("type", "file");
    fieldElement.setAttribute("name", "profile[images][]");
    fieldElement.setAttribute("accept", "image/png, image/jpeg");
    fieldElement.setAttribute("class", className);
    insertTargetElement.append(fieldElement);
  }

  addProfileImageFieldForPc(event) {
    const className =
      "block w-96 text-sm text-gray-900 border border-gray-300 rounded-md cursor-pointer bg-white focus:outline-none mb-4";
    this.addProfileImageField(event, className);
  }

  addProfileImageFieldForSp(event) {
    const className =
      "block w-full text-sm text-gray-900 border border-gray-300 rounded-md cursor-pointer bg-white focus:outline-none mb-4";
    this.addProfileImageField(event, className);
  }

  async showQrcode() {
    const profileUrl = new URL(
      `@${this.usernameValue}`,
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
}
