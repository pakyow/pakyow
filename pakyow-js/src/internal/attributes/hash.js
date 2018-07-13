export default class {
  constructor(attribute, view) {
    this.attribute = attribute;
    this.view = view;
  }

  set(part, value) {
    this.view.node.style[part] = value;
  }

  replace(value) {
    this.view.node.style = {};

    for (let key in value) {
      this.set(key, value[key]);
    }
  }

  delete(part) {
    this.view.node.style[part] = null;
  }

  clear() {
    this.view.node.setAttribute("style", "");
  }
}
