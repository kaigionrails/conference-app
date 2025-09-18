import { Controller } from "@hotwired/stimulus";
import { FetchRequest } from "@rails/request.js";
import { locales } from "locales";

export default class extends Controller {
  static values = {
    alreadySubscribed: { type: Boolean, default: false },
    currentLocale: { type: String, default: "ja" },
  };
  static targets = ["status", "sendSample"];

  async connect() {
    await this.getSubscriptionStatus();
    this.currentLocaleValue = document.documentElement.lang;
    locales.locale = this.currentLocaleValue;
  }

  async toggleSubscriptionStatus() {
    this.statusTarget.disabled = true;
    if ("serviceWorker" in navigator) {
      const serviceWorkerRegistration = await navigator.serviceWorker.ready;
      if (this.alreadySubscribedValue) {
        // unsubscribe
        const subscription =
          await serviceWorkerRegistration.pushManager.getSubscription();
        try {
          await subscription?.unsubscribe();
          this.alreadySubscribedValue = false;
        } catch (error) {
          console.error(error);
          window.alert(locales.t("setting.index.something_went_wrong"));
        }
      } else {
        // subscribe
        try {
          const subscribe =
            await serviceWorkerRegistration.pushManager.subscribe({
              userVisibleOnly: true,
              applicationServerKey: window.vapidPublicKey,
            });
          const request = new FetchRequest("post", "/webpush_subscription", {
            body: { subscription: subscribe.toJSON() },
          });
          const response = await request.perform();
          if (response.ok) {
            this.alreadySubscribedValue = true;
          } else {
            console.error(response);
            window.alert(locales.t("setting.index.something_went_wrong"));
          }
        } catch (error) {
          console.error(error);
          window.alert(locales.t("setting.index.something_went_wrong"));
        }
      }
    } else {
      window.alert(
        locales.t("setting.index.your_browser_does_not_support_webpush")
      );
    }
    this.statusTarget.disabled = false;
    this.updateSubscriptionButton();
  }

  async getSubscriptionStatus() {
    if ("serviceWorker" in navigator) {
      navigator.serviceWorker.ready.then((serviceWorkerRegistration) => {
        serviceWorkerRegistration.pushManager
          .getSubscription()
          .then((subscription) => {
            if (subscription == null) {
              this.alreadySubscribedValue = false;
              this.sendSampleTarget.disabled = true;
            } else {
              this.alreadySubscribedValue = true;
              this.sendSampleTarget.disabled = false;
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
    if (this.alreadySubscribedValue) {
      this.sendSampleTarget.disabled = false;
      this.statusTarget.innerText = locales.t(
        "setting.index.already_subscribed"
      );
    } else {
      this.sendSampleTarget.disabled = true;
      this.statusTarget.innerText = locales.t(
        "setting.index.enable_push_notification"
      );
    }
  }
}
