import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select"];

  connect() {}

  submitDevice() {
    this.setDeviceId(this.selectTarget.value);
  }

  setDeviceId(id) {
    localStorage.setItem("conference-app:deviceId", id);
  }

  removeDeviceId() {
    localStorage.removeItem("conference-app:deviceId");
  }
}
