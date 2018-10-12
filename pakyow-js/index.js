import * as pw from "./src";
import {default as Transformer} from "./src/internal/transformer";

pw.ready(function () {
  var pwGlobal = new (pw.Component.create())(new pw.View(document), {});

  pwGlobal.listen("pw:socket:connected", () => {
    pw.server.reachable = true;
  });

  pwGlobal.listen("pw:socket:disconnected", () => {
    pw.server.reachable = false;
  });

  pwGlobal.listen("pw:socket:disappeared", () => {
    pw.server.reachable = false;
  });

  pwGlobal.listen("pw:socket:message:transformation", (message) => {
    new Transformer(message);
  });

  pw.Component.init(document.querySelector("html"));
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
