// TODO: we should be able to rely on webpack to handle these polyfills for us
import "core-js/fn/symbol/iterator.js";
import "core-js/es6/symbol.js";
import "core-js/fn/array/find.js";

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
