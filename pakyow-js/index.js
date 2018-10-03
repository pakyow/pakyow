import * as pw from "./src";
import {default as Transformer} from "./src/internal/transformer";

pw.inits.push(function () {
  window.socket = new pw.Socket();
  window.socket.subscribe("transformation", function (payload) {
    new Transformer(payload.message);
  });
});

pw.inits.push(function () {
  pw.Component.init(document.querySelector("html"));
});

pw.ready(function () {
  pw.inits.forEach(function (fn) {
    fn();
  });
});

// Wake detection inspired by Alex MacCaw:
//   https://blog.alexmaccaw.com/javascript-wake-event
var wakeTimeout = 10000;
var lastKnownTime = (new Date()).getTime();
setInterval(function() {
  var currentTime = (new Date()).getTime();
  if (currentTime > (lastKnownTime + wakeTimeout + 1000)) {
    pw.wakes.forEach(function (fn) {
      fn();
    });
  }
  lastKnownTime = currentTime;
}, wakeTimeout);

export default pw;
