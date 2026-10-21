/* eslint-disable no-undef */
// Firebase Messaging Service Worker for background notifications
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// Self-contained fallback configuration
const defaultConfig = {
  apiKey: "AIzaSyDX-78vOhXtD31kli0rEG_BRvS_-Su5byg",
  authDomain: "amma-travels-a3257.firebaseapp.com",
  projectId: "amma-travels-a3257",
  storageBucket: "amma-travels-a3257.firebasestorage.app",
  messagingSenderId: "713353882232",
  appId: "1:713353882232:web:f30d88b51487f95ebedb8d",
};

try {
  if (!firebase.apps.length) {
    firebase.initializeApp(defaultConfig);
  }
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Background message received:', payload);
    const title = payload.notification?.title || payload.data?.title || 'Amma Travels';
    const options = {
      body: payload.notification?.body || payload.data?.body || '',
      icon: '/icons/Icon-192.png',
      data: payload.data || {},
    };

    self.registration.showNotification(title, options);
  });
} catch (err) {
  console.warn('Firebase background messaging setup:', err.message);
}

// Resilient fallback listener for Web Push events
self.addEventListener('push', (event) => {
  if (event.data) {
    try {
      const data = event.data.json();
      const title = data.notification?.title || data.title || 'Amma Travels';
      const options = {
        body: data.notification?.body || data.body || '',
        icon: '/icons/Icon-192.png',
        data: data.data || {},
      };
      event.waitUntil(self.registration.showNotification(title, options));
    } catch (err) {
      event.waitUntil(
        self.registration.showNotification('Amma Travels Notification', {
          body: event.data.text(),
          icon: '/icons/Icon-192.png',
        })
      );
    }
  }
});

// Focus or open the profile page when user clicks on a notification
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('/');
      }
    })
  );
});
