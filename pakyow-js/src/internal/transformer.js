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

      if (methodName.substr(methodName.length - 1) === "=") {
        methodName = methodName.substr(0, methodName.length - 1);
        methodName = `set${methodName.charAt(0).toUpperCase() + methodName.substr(1)}`;
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
