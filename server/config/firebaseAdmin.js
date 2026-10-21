const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

let isInitialized = false;

const getCredential = (certParam) => {
  if (typeof admin.cert === 'function') {
    return admin.cert(certParam);
  }
  if (admin.credential && typeof admin.credential.cert === 'function') {
    return admin.credential.cert(certParam);
  }
  return null;
};

try {
  // Option 1: Check if serviceAccountKey.json exists
  const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
    ? path.resolve(process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
    : path.resolve(__dirname, '../serviceAccountKey.json');

  if (fs.existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({
      credential: getCredential(serviceAccount),
    });
    isInitialized = true;
    console.log('Firebase Admin SDK initialized successfully from service account file.');
  } else if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    // Option 2: Raw JSON string in environment variable
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
    admin.initializeApp({
      credential: getCredential(serviceAccount),
    });
    isInitialized = true;
    console.log('Firebase Admin SDK initialized successfully from FIREBASE_SERVICE_ACCOUNT_JSON env.');
  } else if (process.env.FIREBASE_PROJECT_ID && process.env.FIREBASE_CLIENT_EMAIL && process.env.FIREBASE_PRIVATE_KEY) {
    // Option 3: Individual credentials in environment variables
    const privateKey = process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n');
    admin.initializeApp({
      credential: getCredential({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey: privateKey,
      }),
    });
    isInitialized = true;
    console.log('Firebase Admin SDK initialized successfully from individual environment variables.');
  } else {
    console.warn('[Firebase Admin Warning] No Firebase service account credentials detected. Push notifications will be logged but not delivered until serviceAccountKey.json or env variables are set.');
  }
} catch (error) {
  console.error('Error during Firebase Admin SDK initialization:', error.message);
}

module.exports = {
  admin,
  isInitialized: () => isInitialized,
};
