hljs.initHighlightingOnLoad();

var Omoikane = Omoikane || {};

Omoikane.connectForPushNotifications = function(appKey, authorName) {
  var pusher = new Pusher(appKey);
  var channel = pusher.subscribe(authorName);
  channel.bind('finished-or-errored', function(data) {
    // Possibly change the UI, such as icons and highlighting queries,
    // when we receive notifications
    new Notification(data.message);
  });
}

Omoikane.requestPushNotifications = function(appKey, authorName, callback) {
  if (!("Notification" in window)) return;

  // Let's check if the user is okay to get some notification
  if (Notification.permission === "granted") {
    Omoikane.connectForPushNotifications(appKey, authorName);
    callback();
  }

  // Otherwise, we need to ask the user for permission
  // Note, Chrome does not implement the permission static property
  // So we have to check for NOT 'denied' instead of 'default'
  if (Notification.permission !== 'denied') {
    Notification.requestPermission(function (permission) {
      // Whatever the user answers, we make sure we store the information
      if (!('permission' in Notification)) {
        Notification.permission = permission;
      }

      // If the user is okay, let's create a notification
      if (permission === "granted") {
        Omoikane.connectForPushNotifications(appKey, authorName);
        callback();
      }
    });
  }

  // At last, if the user already denied any notification, and you
  // want to be respectful there is no need to bother them any more.
}

Omoikane.arePushNotificationsEnabled = function() {
  return Notification.permission === "granted";
}

Omoikane.boot = function() {
  var appKey = $("meta[name='x-omoikane-pusher-app-key']").attr("content")
  var author = $("meta[name='x-omoikane-author']").attr("content")

  if (Omoikane.arePushNotificationsEnabled()) {
    $("#push-notifications-enabled").show();
    Omoikane.connectForPushNotifications(appKey, author)
  } else {
    $("#push-notifications-disabled").show();
    $("#enable-push-notifications").click(function() {
      Omoikane.requestPushNotifications(appKey, author, function() {
        $("#push-notifications-disabled").hide();
        $("#push-notifications-enabled").show();
      });
    });
  }
}

$(Omoikane.boot);
