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

Omoikane.drawResultsGraph = function(element, results, callback) {
  var columnHeaders = results.find("thead th").map(function(_, e) { return e.innerText; })
    , colsCount = columnHeaders.length
    , rowsCount = results.find("tbody tr").length
    , rowHeadersCount
    , cells = results.find("tbody td")
    , cellValues = cells.map(function(_, td) { return td.innerText; })
    , options = {}
    , i, j, data = [];

  for(j = 0; j < colsCount; j++) {
    if (!(parseFloat(cellValues[ j ]).toString() === cellValues[ j ])) {
      rowHeadersCount = j + 1;
    }
  }

  data.push(["x"]);
  for(i = 0; i < rowsCount; i++) {
    var header = cellValues.slice( colsCount * i, colsCount * i + rowHeadersCount ).toArray().join(" ");
    data[0].push(header);
  }

  for(i = rowHeadersCount; i < colsCount; i++) {
    data.push([columnHeaders[i]]);
  }

  for(j = rowHeadersCount; j < colsCount; j++) {
    for(i = 0; i < rowsCount; i++) {
      var value = cellValues[ colsCount * i + j];
      data[j - rowHeadersCount + 1][i + 1] = value;
    }
  }

  options = {
    bindto: element,
    data: {
      x: 'x',
      type: 'bar',
      columns: data
    },
    axis: {
      rotated: false,
      x: {
        type: "category", // this needed to load string x value
        label: {
          text: "",
          position: "outer-center"
        }
      },
      y: {
        label: {
          text: "", // without this empty label, values are cutoff and we can't read them
          position: "outer-middle"
        }
      }
    },
    tooltip: {
      show: false
    },
    bar: {
      width: {
        ratio: 0.5
      }
    }
  }

  if (rowsCount > 10) options.data.type = 'line';
  if (rowHeadersCount === 1 && cellValues[0].match(/^\d{4}(.)\d{2}\1\d{2}/)) {
    options.data.type = 'spline';
    options.axis.x.type = 'timeseries';
  }

  var chart = c3.generate(options);

  callback();
}

Omoikane.boot = function() {
  var appKey = $("meta[name='x-omoikane-pusher-app-key']").attr("content")
  var author = $("meta[name='x-omoikane-author']").attr("content")

  if (appKey === undefined) {
    $("#welcome").show();
  } else if (Omoikane.arePushNotificationsEnabled()) {
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

  $("#graph-this").click(function(e) {
    e.preventDefault();

    Omoikane.drawResultsGraph("#graph", $("#results"), function() {
      $("#graph-this").hide('fast');
      $("#graph-container").slideDown('slow');
    });
  }).show();
}

$(Omoikane.boot);
