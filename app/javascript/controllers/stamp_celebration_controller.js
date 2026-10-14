import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  prepareForCache() {
    this.element.querySelectorAll("[data-completion-reveal]").forEach((panel) => {
      panel.classList.remove("stamp-rally-completion-panel--new");
      panel.removeAttribute("data-completion-reveal");
      panel.querySelector(".stamp-rally-completion-panel-sparkles")?.remove();
    });
    this.element.querySelectorAll("[data-new-stamp-celebration]").forEach((stage) => {
      stage.classList.remove("stamp-rally-stamp-stage--new", "stamp-rally-stamp-stage--complete");
      stage.removeAttribute("data-new-completion-celebration");
      stage.removeAttribute("data-new-stamp-celebration");
      stage.querySelectorAll(".stamp-rally-stamp-burst, .stamp-rally-confetti, .stamp-rally-stamp-new-label").forEach((decoration) => decoration.remove());
    });
    this.element.querySelectorAll(".community-stamp-count--updated").forEach((count) => {
      count.classList.remove("community-stamp-count--updated");
    });
  }
}
