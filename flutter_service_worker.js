self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(list => {
      if (list.length) {
        // Find the first client that can be focused.
        let client = null;
        for (let i = 0; i < list.length; i++) {
          if (list[i].focus) {
            client = list[i];
            break;
          }
        }
        if (client) {
          return client.focus();
        }
      }
      return clients.openWindow('/');
    })
  );
});
