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

export default pw;
