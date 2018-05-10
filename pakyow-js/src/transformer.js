export default class {
  constructor(transformation) {
    this.id = transformation.id;
    this.process(transformation.calls);
  }

  process (calls) {
    // TODO: handle case where the starting point is missing
    for (let node of document.querySelectorAll("*[data-t='" + this.id + "']")) {
      this.transform(calls,  new pw.View(node));
    }
  }

  transform(calls, transformable) {
    for (let transformation of calls) {
      var method = transformable[transformation[0]];

      if (method) {
        // TODO: handle `each` transforms (index 2)
        this.transform(transformation[3], method.apply(transformable, transformation[1]));
      } else {
        console.log(`unknown view method: ${transformation[0]}`);
      }
    }
  }
}
