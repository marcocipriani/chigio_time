// Firebase Messaging service worker for web push notifications.
// Must live at /firebase-messaging-sw.js (web root).

importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDbFkR0bAvxJtJKnnDXYFjS5rqmk_5YYfM',
  authDomain: 'chigio-time-pcm.firebaseapp.com',
  projectId: 'chigio-time-pcm',
  storageBucket: 'chigio-time-pcm.firebasestorage.app',
  messagingSenderId: '549971944238',
  appId: '1:549971944238:web:e7c364b8881cce40b150bf',
});

const messaging = firebase.messaging();

// Background push handler: show notification when app tab is not in focus.
messaging.onBackgroundMessage((payload) => {
  const { title = 'Chigio Time', body = '' } = payload.notification ?? {};
  return self.registration.showNotification(title, {
    body,
    icon: '/icons/web-app-manifest-192x192.png',
    badge: '/icons/favicon-96x96.png',
    data: payload.data ?? {},
  });
});
