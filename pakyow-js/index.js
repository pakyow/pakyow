import * as pw from "./src";

pw.inits.push(function () {
  window.socket = new pw.Socket();

  window.socket.subscribe("transformation", function (payload) {
    new pw.Transformer(payload.message);
  });
});

pw.ready(function () {
  pw.inits.forEach(function (fn) {
    fn();
  });
});

export default pw;
