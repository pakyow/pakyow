import * as pw from "./src";
import {default as Transformer} from "./src/internal/transformer";

pw.ready(function () {
  pw.logger.install();

  var pwGlobal = new (pw.Component.create())(new pw.View(document), {});

  pwGlobal.listen("pw:socket:connected", (socket) => {
    if (socket.config.global) {
      pw.server.reachable = true;
      pw.server.socket = socket;
      pw.logger.flush();
    }
  });

  pwGlobal.listen("pw:socket:disconnected", (socket) => {
    if (socket.config.global) {
      pw.server.reachable = false;
      pw.server.socket = null;
    }
  });

  pwGlobal.listen("pw:socket:disappeared", (socket) => {
    if (socket.config.global) {
      pw.server.reachable = false;
    }
  });

  pwGlobal.listen("pw:socket:message:transformation", (message) => {
    new Transformer(message);
  });

  pw.Component.init(document.querySelector("html"));
});

export default pw;
