const installHandler = async (event) => {
  console.info(event);
};

const pushHandler = async (event) => {
  const notificationData = event.data.json();
  const notificationPromise = self.registration.showNotification(
    notificationData.title,
    {
      body: notificationData.body,
      icon: notificationData.icon,
    }
  );
  event.waitUntil(notificationPromise);
};

self.addEventListener("install", installHandler);
self.addEventListener("push", pushHandler);
