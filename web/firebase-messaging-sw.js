importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
    apiKey: "AIzaSyAaawTqisHVCgYpDZlqjx8S9bR_iIfZWas",
    authDomain: "rescatadores-app-9ea9d-df9dd.firebaseapp.com",
    projectId: "asesor-app-9ea9d",
    storageBucket: "asesor-app-9ea9d.firebasestorage.app",
    messagingSenderId: "506221282284",
    appId: "1:506221282284:web:f3410415bd7bfc4d07f6c9",
    measurementId: "G-FX9H53H02B",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('Received background message:', payload);

    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});