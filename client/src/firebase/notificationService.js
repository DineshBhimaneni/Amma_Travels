import { getToken, onMessage } from 'firebase/messaging';
import { getMessagingInstance, isConfigured } from './firebaseConfig';
import api from '../services/api';

/**
 * Requests browser notification permission, fetches the FCM registration token,
 * and sends the token to the backend to link it with the current MySQL user.
 */
export const requestAndSyncFcmToken = async () => {
  try {
    if (!isConfigured) {
      console.info('[FCM Notice] Firebase Web configuration is not set in client/.env yet.');
      return null;
    }

    if (!('Notification' in window) || !('serviceWorker' in navigator)) {
      console.warn('Push Notifications or Service Workers are not supported in this browser.');
      return null;
    }

    // Request notification permission if not yet decided
    let permission = Notification.permission;
    if (permission === 'default') {
      permission = await Notification.requestPermission();
    }

    if (permission !== 'granted') {
      console.log('Notification permission was not granted by user.');
      return null;
    }

    // Register Firebase Messaging Service Worker
    const swRegistration = await navigator.serviceWorker.register('/firebase-messaging-sw.js', {
      scope: '/',
    });
    await navigator.serviceWorker.ready;

    const messaging = await getMessagingInstance();
    if (!messaging) {
      console.warn('Firebase Messaging instance unavailable.');
      return null;
    }

    const vapidKey = import.meta.env.VITE_FIREBASE_VAPID_KEY;
    const tokenOptions = {
      serviceWorkerRegistration: swRegistration,
    };

    if (vapidKey && vapidKey !== 'YOUR_PUBLIC_VAPID_KEY') {
      tokenOptions.vapidKey = vapidKey;
    }

    const fcmToken = await getToken(messaging, tokenOptions);

    if (fcmToken) {
      console.log('[FCM Success] Registration token obtained:', fcmToken);

      // Save locally to avoid duplicate calls
      const lastSavedToken = localStorage.getItem('last_synced_fcm_token');
      if (lastSavedToken !== fcmToken) {
        // Send FCM token to Node.js backend for the currently authenticated user
        await api.post('/users/fcm-token', { fcm_token: fcmToken });
        localStorage.setItem('last_synced_fcm_token', fcmToken);
        console.log('[FCM Success] FCM token synchronized with backend database.');
      }
      return fcmToken;
    } else {
      console.warn('No FCM registration token available.');
      return null;
    }
  } catch (error) {
    console.error('Error in requestAndSyncFcmToken:', error);
    return null;
  }
};

/**
 * Sets up a listener for push notifications arriving while the app is in the foreground.
 */
export const setupForegroundListener = async (onNotificationReceived) => {
  try {
    const messaging = await getMessagingInstance();
    if (!messaging) return null;

    const unsubscribe = onMessage(messaging, (payload) => {
      console.log('[FCM Foreground Message Received]:', payload);

      const title = payload.notification?.title || payload.data?.title || 'Amma Travels';
      const body = payload.notification?.body || payload.data?.body || '';

      // Trigger custom UI callback (e.g. toast notification)
      if (typeof onNotificationReceived === 'function') {
        onNotificationReceived({
          title,
          body,
          data: payload.data,
        });
      }

      // Also display browser native notification if permitted
      if (Notification.permission === 'granted') {
        try {
          new Notification(title, {
            body,
            icon: '/favicon.svg',
            data: payload.data,
          });
        } catch (e) {
          console.warn('Native notification display failed:', e);
        }
      }
    });

    return unsubscribe;
  } catch (error) {
    console.error('Error setting up foreground notification listener:', error);
    return null;
  }
};
