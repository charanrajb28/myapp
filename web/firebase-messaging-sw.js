importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

// Initialize Firebase App in Service Worker with project config
firebase.initializeApp({
  apiKey: 'AIzaSyA4vSzlus2IKiZCETtioVwNOv9LErw2Td0',
  appId: '1:238760860837:web:4ba5dd024e5311bd0a814c',
  messagingSenderId: '238760860837',
  projectId: 'aaroha-af3cb',
  authDomain: 'aaroha-af3cb.firebaseapp.com',
  storageBucket: 'aaroha-af3cb.firebasestorage.app',
  measurementId: 'G-DZVDG3XG2N',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification ? payload.notification.title : 'Aaroha Notification';
  const notificationOptions = {
    body: payload.notification ? payload.notification.body : '',
    icon: '/favicon.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
