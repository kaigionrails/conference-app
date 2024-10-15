import { Controller } from "@hotwired/stimulus";
import { FetchRequest } from "@rails/request.js";

export default class extends Controller {
  static values = {
    bookmarked: Boolean,
    talkId: Number,
    talkBookmarkId: Number,
    clicked: { type: Boolean, default: false },
  };
  static targets = ["createTalkBookmarkIcon", "removeTalkBookmarkIcon"];

  async connect() {}

  async toggle() {
    if (this.bookmarkedValue) {
      await this.removeBookmark();
    } else {
      await this.bookmark();
    }
  }

  async bookmark() {
    if (this.clickedValue) {
      return;
    } else {
      this.clickedValue = true;
    }
    this.disableBookmarkIcons();
    const request = new FetchRequest("post", "/talk_bookmarks", {
      body: JSON.stringify({
        talk_bookmark: {
          talk_id: this.talkIdValue,
        },
      }),
      responseKind: "json",
    });
    const response = await request.perform();
    if (response.ok) {
      this.bookmarkedValue = true;
      const body = await response.json;
      this.talkBookmarkIdValue = body.id;
      this.toggleTalkBookmarkIcons();
    } else if (response.unauthenticated) {
      window.alert("ブックマークするにはログインしてください");
    } else {
      console.error(response);
      window.alert("エラーが発生しました。再度お試しください。");
    }
    this.enableBookmarkIcons();
    this.clickedValue = false;
  }

  async removeBookmark() {
    if (this.clickedValue) {
      return;
    } else {
      this.clickedValue = true;
    }
    this.disableBookmarkIcons();
    const request = new FetchRequest(
      "delete",
      `/talk_bookmarks/${this.talkBookmarkIdValue}`,
      { responseKind: "json" }
    );
    const response = await request.perform();
    if (response.ok) {
      this.bookmarkedValue = false;
      this.talkBookmarkIdValue = undefined;
      this.toggleTalkBookmarkIcons();
    } else {
      console.error(response);
    }
    this.enableBookmarkIcons();
    this.clickedValue = false;
  }

  toggleTalkBookmarkIcons() {
    this.removeTalkBookmarkIconTarget.classList.toggle("hidden");
    this.createTalkBookmarkIconTarget.classList.toggle("hidden");
  }

  disableBookmarkIcons() {
    this.removeTalkBookmarkIconTarget.classList.add("opacity-50");
    this.createTalkBookmarkIconTarget.classList.add("opacity-50");
  }

  enableBookmarkIcons() {
    this.removeTalkBookmarkIconTarget.classList.remove("opacity-50");
    this.createTalkBookmarkIconTarget.classList.remove("opacity-50");
  }
}
