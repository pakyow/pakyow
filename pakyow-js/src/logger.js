var unsent = [];

export default class {
  static install() {
    let original = window.console;

    window.console = {
      log: (...args) => {
        pw.logger.log.apply(null, ["unknown", "log"].concat(args));
        original.log.apply(null, args);
      },

      debug: (...args) => {
        pw.logger.log.apply(null, ["debug", null].concat(args));
        original.debug.apply(null, args);
      },

      info: (...args) => {
        pw.logger.log.apply(null, ["info", null].concat(args));
        original.info.apply(null, args);
      },

      warn: (...args) => {
        pw.logger.log.apply(null, ["warn", null].concat(args));
        original.warn.apply(null, args);
      },

      error: (...args) => {
        pw.logger.log.apply(null, ["error", null].concat(args));
        original.error.apply(null, args);
      }
    };

    for (let prop in original) {
      if (!window.console.hasOwnProperty(prop)) {
        window.console[prop] = original[prop];
      }
    }
  }

  static flush() {
    let message;
    while (message = unsent.shift()) {
      this.log.apply(null, [message[0], message[1]].concat(message[2]));
    }
  }

  static log(severity, method, ...messages) {
    if (pw.server.socket && pw.server.reachable) {
      for (let message of messages) {
        pw.server.socket.send({
          severity: severity,
          message: message
        }, "log");
      }
    } else {
      unsent.push([severity, method || severity, messages]);
    }
  }
}
