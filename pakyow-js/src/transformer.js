export default class {
  constructor(transformation) {
    this.id = transformation.transformation_id;
    this.process(transformation.transformations);
  }

  process (transformations) {
    // TODO: handle case where the starting point is missing
    for (let node of document.querySelectorAll("*[data-t='" + this.id + "'")) {
      this.transform(transformations,  new pw.View(node));
    }
  }

  transform(transformations, transformable) {
    for (let transformation of transformations) {
      var method = transformable[transformation[0]];

      if (method) {
        this.transform(transformation[2], method.apply(transformable, transformation[1]));
      } else {
        console.log(`unknown view method: ${transformation[0]}`);
      }
    }
  }
}
