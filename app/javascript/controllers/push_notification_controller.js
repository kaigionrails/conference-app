import { Controller } from "@hotwired/stimulus";
import { FetchRequest } from "@rails/request.js";

export default class extends Controller {
  static values = {
    alreadySubscribed: { type: Boolean, default: false },
  };
  static targets = ["status"];

  async connect() {
    await this.getSubscriptionStatus();
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
                console.log(pushSubscription);
                console.log(pushSubscription.toJSON());
                const request = new FetchRequest(
                  "post",
                  "/webpush_subscription",
                  { body: { subscription: pushSubscription.toJSON() } }
                );
                request.perform().then((response) => {
                  if (response.ok) {
                    this.alreadySubscribedValue = true
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
        this.updateSubscriptionButton()
      });
    } else {
      window.alert("お使いのブラウザはプッシュ通知に対応していません");
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
  updateSubscriptionButton() {
    if (this.alreadySubscribedValue) {
      this.statusTarget.innerText = "講読済み";
      this.statusTarget.disabled = true;
    }
  }
}
