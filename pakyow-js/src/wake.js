var wakes = [];

// Wake detection inspired by Alex MacCaw:
//   https://blog.alexmaccaw.com/javascript-wake-event
var wakeTimeout = 10000;
var lastKnownTime = (new Date()).getTime();
setInterval(function() {
  var currentTime = (new Date()).getTime();
  if (currentTime > (lastKnownTime + wakeTimeout + 1000)) {
    wakes.forEach(function (fn) {
      fn();
    });
  }
  lastKnownTime = currentTime;
}, wakeTimeout);

export default function(callback) {
  wakes.push(callback);
};
