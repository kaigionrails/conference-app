import { Controller } from "@hotwired/stimulus";
import { FetchRequest } from "@rails/request.js";

export default class extends Controller {
  static values = { unreadAnnouncementId: Number };
  static targets = ["button"];

  connect() {}

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
      this.buttonTarget.innerText = "既読済み";
      this.buttonTarget.classList.add("bg-gray-400");
    } else {
      console.error(response);
      window.alert("エラーが発生しました。再度お試しください。");
    }
  }
}
