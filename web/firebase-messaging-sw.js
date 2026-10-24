importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyCqXvNa9fnTUyswJK8zGzOhNVvBJsAVdSs',
  appId: '1:71208201851:web:760e8cbfe84a904394bcde',
  messagingSenderId: '71208201851',
  projectId: 'inventa-5cad4',
  authDomain: 'inventa-5cad4.firebaseapp.com',
  storageBucket: 'inventa-5cad4.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((message) => {
  const title = message.notification?.title ?? 'Inventa';
  const body = message.notification?.body ?? 'Une nouvelle activité vous attend.';

  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
    data: message.data ?? {},
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow('/'));
});
