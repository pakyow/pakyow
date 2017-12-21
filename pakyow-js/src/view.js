export default class {
  constructor(node) {
    this.node = node;
  }

  find (names) {
    if (!Array.isArray(names)) {
      names = [names];
    }

    names = names.slice(0);
    var named = names.shift();
    var found = this.qs(`*[data-s='${named}']:not(script), *[data-p='${named}']:not(script)`);
    var templates = this.qs(`script[data-s='${named}'], script[data-p='${named}']`);

    if (found.length == 0 && templates.length == 0) {
      // There's nothing we can do in this case, except throw our hands in the air.
      return pw.tryTurningItOffAndOnAgain();
    }

    if (names.length == 0) {
      return new pw.ViewSet(found, templates);
    } else if (found.length > 0) {
      return found[0].find(names);
    }
  }

  bind(object) {
    if (!object) {
      return;
    }

    for (var prop of this.qs("*[data-p]:not(script)")) {
      // TODO: handle self-closing tags
      console.log("setting prop", prop.node)
      prop.node.innerText = object[prop.node.getAttribute("data-p")];
    }

    // TODO: anything we should do if object has no id?
    this.node.setAttribute("data-id", object.id);

    return this;
  }

  qs (selector) {
    var results = [];

    for (let node of this.node.querySelectorAll(selector)) {
      results.push(new pw.View(node));
    }

    return results;
  }

  // present (objects) {
  //   if (!Array.isArray(objects)) {
  //     objects = [objects];
  //   }

  //   console.log("View#present", objects);

  //   // TODO: for each object:
  //   //   - [ ] make sure it exists; if not, request view from backend and add it
  //   // TODO: delete views that aren't present in `objects`
  //   // TODO: reorder views based on the order in `objects`
  // }
}
