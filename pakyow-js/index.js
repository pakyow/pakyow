import * as pw from "./src";
import {default as Transformer} from "./src/internal/transformer";

pw.inits.push(function () {
  window.socket = new pw.Socket();
  window.socket.subscribe("transformation", function (payload) {
    new Transformer(payload.message);
  });
});

pw.ready(function () {
  pw.inits.forEach(function (fn) {
    fn();
  });
});

export default pw;
