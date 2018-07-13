export default class {
  constructor(attributes) {
    this.attributes = attributes;
  }

  set(part, value) {
    for (let attribute of this.attributes) {
      attribute.set(part, value);
    }
  }

  add(value) {
    for (let attribute of this.attributes) {
      attribute.add(value);
    }
  }

  delete(part) {
    for (let attribute of this.attributes) {
      attribute.delete(part);
    }
  }

  clear() {
    for (let attribute of this.attributes) {
      attribute.clear();
    }
  }
}
