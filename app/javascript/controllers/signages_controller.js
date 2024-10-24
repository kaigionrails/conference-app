import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["page"];

  connect() {
    this.deviceId = null;
    this.currentSchedule = null;
    this.currentPageIndex = 0;

    this.determineDevice();
    if (this.deviceId === null || this.deviceId === "") {
      location.href = "/signage_devices";
    }

    this.fetchSignage().then(() => this.startSignage());
  }

  determineDevice() {
    this.deviceId = localStorage.getItem("conference-app:deviceId");
  }

  async fetchSignage() {
    this.signage = {};
    await fetch(`/signages.json?device_id=${this.deviceId}`, {
      headers: { "Content-Type": "application/json" },
    })
      .then((response) => response.json())
      .then((data) => {
        this.signage = data;
      });
  }

  startSignage() {
    if (Object.keys(this.signage).length === 0) {
      return; // do nothing
    }
    console.dir(this.signage);
    this.updateCurrentSchedule();
    this.updateSignagePage();
  }

  updateCurrentSchedule() {
    const now = new Date();
    this.signage.panel.schedules.forEach((schedule) => {
      const startAt = new Date(schedule.start_at);
      const endAt = new Date(schedule.end_at);
      console.log(startAt, endAt);
      if (startAt <= now && now < endAt) {
        this.currentSchedule = schedule;
        console.dir(this.currentSchedule);
        return;
      }
    });
  }

  updateSignagePage() {
    if (this.currentPageIndex >= this.currentSchedule.pages.length) {
      this.currentPageIndex = 0;
    }

    const page = this.currentSchedule.pages[this.currentPageIndex];
    this.pageTarget.style.backgroundImage = `url(${page.page_image_url})`;
    console.log(this.pageTarget);
    setTimeout(() => {
      this.currentPageIndex++;
      this.updateSignagePage();
    }, page.duration_second * 1000);
  }
  toggleFullscreen() {
    if (!document.fullscreenElement) {
      this.pageTarget.requestFullscreen();
    } else if (this.pageTarget.exitFullscreen) {
      this.pageTarget.exitFullscreen();
    }
  }
}
