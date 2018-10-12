var reachable = false;

export default class {
  static get reachable() {
    return reachable;
  }

  static set reachable(value) {
    reachable = !!value;
  }
}
