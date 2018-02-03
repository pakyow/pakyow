var Inflector = require("inflector-js");

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

    var found = this.bindingScopes().concat(this.bindingProps()).filter((binding) => {
      return binding.name == named;
    }).map((binding) => { return new pw.View(binding.node) });

    var templates = this.qs(`script[data-b='${named}']`);
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

    for (let binding of this.bindingProps()) {
      binding.node.innerText = object[binding.name];
    }

    // TODO: anything we should do if object has no id?
    this.node.setAttribute("data-id", object.id);

    return this;
  }

  transform(object) {
    if (!object || (Array.isArray(object) && object.length == 0) || Object.getOwnPropertyNames(object).length == 0) {
      this.remove();
    } else {
      for (let binding of this.bindingProps()) {
        if (!object[binding.name]) {
          new pw.View(binding.node).remove();
        }
      }
    }

    return this;
  }

  present(object) {
    this.transform(object).bind(object);

    // present recursively

    var bindingScopeNames = new Set(
      this.bindingScopes(true).map(
        (binding) => { return binding.name; }
      )
    );

    for (let binding of bindingScopeNames) {
      var pluralBinding = Inflector.pluralize(binding);

      var data = [];
      if (binding in object) {
        data = object[binding];
      } else if (pluralBinding in object) {
        data = object[pluralBinding];
      }

      this.find(binding).present(data);
    }

    return this;
  }

  qs (selector) {
    var results = [];

    for (let node of this.node.querySelectorAll(selector)) {
      results.push(new pw.View(node));
    }

    return results;
  }

  remove() {
    this.node.parentNode.removeChild(this.node);
  }

  bindingScopes(includeScripts = false) {
    var bindings = [];

    this.breadthFirst(this.node, function(childNode, halt) {
      if (childNode == this.node) {
        return; // we only care about the children
      }

      if (childNode.hasAttribute("data-b") && new pw.View(childNode).bindingProps().length > 0) {
        bindings.push({
          name: childNode.getAttribute("data-b"),
          node: childNode
        });
      }
    }, includeScripts);

    return bindings;
  }

  bindingProps() {
    var bindings = [];

    this.breadthFirst(this.node, function(childNode, halt) {
      if (childNode == this.node) {
        return; // we only care about the children
      }

      if (childNode.hasAttribute("data-b")) {
        if (new pw.View(childNode).bindingProps().length == 0) {
          bindings.push({
            name: childNode.getAttribute("data-b"),
            node: childNode
          });
        } else {
          halt(); // we're done here
        }
      }
    });

    return bindings;
  }

  breadthFirst(node, cb, includeScripts = false) {
    var queue = [node];
    var halted = false;
    var halt = function () { halted = true; }
    while (!halted && queue.length > 0) {
      var subNode = queue.shift();
      if (!subNode) continue;
      if(typeof subNode == "object" && "nodeType" in subNode && subNode.nodeType === 1 && subNode.cloneNode) {
        cb.call(this, subNode, halt);
      }

      var children = subNode.childNodes;
      if (children) {
        for(var i = 0; i < children.length; i++) {
          if (includeScripts || children[i].tagName != "SCRIPT") {
            queue.push(children[i]);
          }
        }
      }
    }
  }
}
