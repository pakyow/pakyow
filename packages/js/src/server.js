var reachable = false;
var socket;

export default class {
  static get reachable() {
    return reachable;
  }

  static set reachable(value) {
    reachable = !!value;
  }

  static get socket() {
    return socket;
  }

  static set socket(value) {
    socket = value;
  }
}
