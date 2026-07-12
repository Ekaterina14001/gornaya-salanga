importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage(function (payload) {
  const title = payload.notification?.title || 'Горная Саланга';
  const options = {
    body: payload.notification?.body || '',
  };
  self.registration.showNotification(title, options);
});
