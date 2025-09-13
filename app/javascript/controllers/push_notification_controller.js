import { Controller } from "@hotwired/stimulus";
import { FetchRequest } from "@rails/request.js";
import { locales } from "locales";

export default class extends Controller {
  static values = {
    alreadySubscribed: { type: Boolean, default: false },
    currentLocale: { type: String, default: "ja" },
  };
  static targets = ["status"];

  async connect() {
    await this.getSubscriptionStatus();
    this.currentLocaleValue = document.documentElement.lang
    locales.locale = this.currentLocaleValue
  }

  async subscribe() {
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.ready.then((serviceWorkerRegistration) => {
        if (!this.alreadySubscribedValue) {
          serviceWorkerRegistration.pushManager
            .subscribe({
              userVisibleOnly: true,
              applicationServerKey: window.vapidPublicKey,
            })
            .then(
              (pushSubscription) => {
                const request = new FetchRequest(
                  "post",
                  "/webpush_subscription",
                  { body: { subscription: pushSubscription.toJSON() } }
                );
                request.perform().then((response) => {
                  if (response.ok) {
                    this.alreadySubscribedValue = true;
                  } else {
                    console.error(response);
                  }
                });
              },
              (error) => {
                console.error(error);
              }
            );
        }
        this.updateSubscriptionButton();
      });
    } else {
      window.alert(locales.t("setting.index.your_browser_does_not_support_webpush"));
    }
  }

  async getSubscriptionStatus() {
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.ready.then((serviceWorkerRegistration) => {
        serviceWorkerRegistration.pushManager
          .getSubscription()
          .then((subscription) => {
            if (subscription == null) {
              this.alreadySubscribedValue = false;
            } else {
              this.alreadySubscribedValue = true;
            }
            this.updateSubscriptionButton();
          });
      });
    }
  }

  async sendSamplePushNotification() {
    const request = new FetchRequest("post", "/sample_webpush_notifications");
    const response = await request.perform();
    if (!response.ok) {
      console.error(response);
    }
  }

  updateSubscriptionButton() {
    this.statusTarget.innerText = locales.t("setting.index.already_subscribed");
    this.statusTarget.disabled = true;
  }
}
