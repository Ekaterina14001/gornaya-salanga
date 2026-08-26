importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDlA-UOT9QRmsCzbPAz0slbOJZs0nJ1z74',
  appId: '1:1086667583372:web:c702884271879f377870a9',
  messagingSenderId: '1086667583372',
  projectId: 'gornaya-slanga',
  authDomain: 'gornaya-slanga.firebaseapp.com',
  storageBucket: 'gornaya-slanga.firebasestorage.app',
});

const messaging = firebase.messaging();
messaging.onBackgroundMessage(function (payload) {
  const title = payload.notification?.title || 'Горная Саланга';
  const link = payload.data?.linkUrl || payload.data?.link || '/app/#/notifications';
  const options = {
    body: payload.notification?.body || '',
    data: { linkUrl: link },
  };
  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', function (event) {
  event.notification.close();
  const link = event.notification.data?.linkUrl || '/app/#/notifications';
  const url = link.startsWith('http') ? link : self.location.origin + (link.startsWith('/') ? link : '/app/#/notifications');
  event.waitUntil(clients.openWindow(url));
});
