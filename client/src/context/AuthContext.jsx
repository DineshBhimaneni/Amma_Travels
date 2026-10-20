import React, { createContext, useState, useEffect } from 'react';
import api from '../services/api';
import { requestAndSyncFcmToken, setupForegroundListener } from '../firebase/notificationService';
import Toast from '../components/Toast';

export const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [notificationToast, setNotificationToast] = useState(null);

  useEffect(() => {
    // Check if user is logged in
    const checkLoggedIn = async () => {
      const token = localStorage.getItem('token');
      if (token) {
        try {
          const res = await api.get('/users/profile');
          setUser(res.data);
        } catch (error) {
          console.error('Failed to authenticate token:', error);
          localStorage.removeItem('token');
        }
      }
      setLoading(false);
    };

    checkLoggedIn();
  }, []);

  // When user is authenticated, sync FCM registration token with MySQL backend
  useEffect(() => {
    if (!user) return;

    // Request notification permission and send token to backend
    requestAndSyncFcmToken();

    // Setup foreground notification handler
    let unsubscribe = null;
    setupForegroundListener((payload) => {
      const msg = payload.title ? `${payload.title}: ${payload.body}` : payload.body;
      setNotificationToast(msg);
    }).then((unsub) => {
      unsubscribe = unsub;
    });

    return () => {
      if (unsubscribe) unsubscribe();
    };
  }, [user]);

  const login = (userData, token) => {
    localStorage.setItem('token', token);
    setUser(userData);
  };

  const logout = () => {
    if (localStorage.getItem('token')) {
      api.post('/users/fcm-token', { fcm_token: null }).catch(() => {});
    }
    localStorage.removeItem('token');
    localStorage.removeItem('last_synced_fcm_token');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, loading, requestAndSyncFcmToken }}>
      {notificationToast && (
        <Toast
          message={notificationToast}
          type="info"
          onClose={() => setNotificationToast(null)}
        />
      )}
      {!loading && children}
    </AuthContext.Provider>
  );
};
