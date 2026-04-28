// Stub service worker for firebase-messaging.
// Roomr does not use push notifications yet — this file exists only to
// satisfy the Firebase Web SDK's auto-registration check. Without it, the
// SDK throws a "failed-service-worker-registration" error during signOut.

self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => event.waitUntil(self.clients.claim()));
