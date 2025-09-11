import { Controller } from "@hotwired/stimulus";
import { FetchRequest } from "@rails/request.js";
import { locales } from "locales";

export default class extends Controller {
  static values = {
    unreadAnnouncementId: Number,
    currentLocale: { type: String, default: "ja" },
   };
  static targets = ["button"];

  connect() {
    this.currentLocaleValue = document.documentElement.lang
    locales.locale = this.currentLocaleValue
  }

  async read() {
    const request = new FetchRequest(
      "delete",
      `/unread_announcements/${this.unreadAnnouncementIdValue}`,
      {
        responseKind: "json",
      }
    );
    const response = await request.perform();
    if (response.ok) {
      this.buttonTarget.innerText = locales.t("announcements.index.read");
      this.buttonTarget.classList.add("bg-gray-400");
    } else {
      console.error(response);
      window.alert(locales.t("announcements.index.something_went_wrong"));
    }
  }
}
