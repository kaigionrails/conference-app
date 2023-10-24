import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    if (window.location.search.includes("token=")) {
      const url = new URL(window.location);
      console.info(url);
      url.search = "";
      console.info(url);
      history.replaceState({}, document.title, url);
    }
  }
}
