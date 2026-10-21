import { initializeApp, getApps } from 'firebase/app';
import { getMessaging, isSupported } from 'firebase/messaging';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

let app = null;

// Only initialize if mandatory Firebase config is present
const isConfigured = Boolean(
  firebaseConfig.apiKey &&
  firebaseConfig.projectId &&
  firebaseConfig.apiKey !== 'YOUR_FIREBASE_API_KEY'
);

if (isConfigured) {
  try {
    app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];
  } catch (error) {
    console.error('Error initializing Firebase Web Client:', error);
  }
}

export const getMessagingInstance = async () => {
  if (!app) {
    return null;
  }
  try {
    const supported = await isSupported().catch(() => false);
    if (supported) {
      return getMessaging(app);
    }
  } catch (error) {
    console.warn('Firebase Messaging not supported in this browser environment:', error);
  }
  return null;
};

export { app, isConfigured };
