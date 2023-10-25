import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["preview"];
  connect() {}

  updatePreview(event) {
    if (event.target.id === "profile_badge_text") {
      this.previewTarget.innerText = event.target.value;
    } else if (event.target.id == "profile_badge_border_color_code") {
      this.previewTarget.style.borderColor = event.target.value;
    } else if (event.target.id == "profile_badge_background_color_code") {
      this.previewTarget.style.backgroundColor = event.target.value;
    }
  }

  confirmDelete(event) {
    event.preventDefault();
    if (window.confirm("Are you sure?")) {
      event.target.submit();
    }
  }
}
