export default class {
  constructor(attribute, view) {
    this.attribute = attribute;
    this.view = view;
  }

  add (value) {
    this.view.node.classList.add(value);
  }

  delete(value) {
    this.view.node.classList.remove(value);
  }

  clear() {
    this.view.node.setAttribute("class", "");
  }
}
