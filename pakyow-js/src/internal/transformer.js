export default class {
  constructor(transformation) {
    this.id = transformation.id;
    this.process(transformation.calls);
  }

  process (calls) {
    for (let node of document.querySelectorAll("*[data-t='" + this.id + "']")) {
      this.transform(calls, new pw.View(node));
    }
  }

  transform(calls, transformable) {
    for (let transformation of calls) {
      let methodName = transformation[0];

      if (methodName === "[]=") {
        methodName = "set";
      }

      if (methodName === "[]") {
        methodName = "get";
      }

      if (methodName === "<<") {
        methodName = "add";
      }

      if (methodName === "attrs") {
        methodName = "attributes";
      }

      let method = transformable[methodName];

      if (method) {
        let args = transformation[1];

        if (transformation[2].length > 0) {
          let i = 0;
          args.push((view, object) => {
            this.transform(transformation[2][i], view);
            i++;
          });
        }

        this.transform(
          transformation[3],
          method.apply(
            transformable,
            args
          )
        );
      } else {
        console.log(`unknown view method: ${methodName}`, transformable);
      }
    }
  }
}
