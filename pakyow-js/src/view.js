import {default as ViewAttributes} from "./internal/view_attributes";
import {default as ViewSet} from "./internal/view_set";

export default class {
  constructor(node, versions) {
    this.node = node;
    this.versions = versions;
  }

  id() {
    return this.node.getAttribute("data-id");
  }

  binding() {
    return this.node.getAttribute("data-b");
  }

  version() {
    return this.node.getAttribute("data-v");
  }

  match(property, value) {
    let propertyValue = this[property]() || "";
    value = String(value)

    if (property === "binding") {
      return propertyValue.startsWith(value);
    } else if (property === "version") {
      return value === propertyValue || (propertyValue === "" && value === "default");
    } else {
      return value === propertyValue;
    }
  }

  find (names) {
    if (!Array.isArray(names)) {
      names = [names];
    }

    names = names.slice(0);
    var named = names.shift();
    var templates = this.templatesNamed(named);

    var found = this.bindingScopes().concat(this.bindingProps()).filter((view) => {
      return view.match("binding", named);
    }).map((view) => {
      return new pw.View(view.node, templates)
    });

    if (found.length == 0 && templates.length == 0) {
      // There's nothing we can do in this case, except throw our hands in the air.
      return pw.tryTurningItOffAndOnAgain();
    }

    if (names.length == 0) {
      return new ViewSet(found, templates);
    } else if (found.length > 0) {
      return found[0].find(names);
    }
  }

  bind(object) {
    if (!object) {
      return;
    }

    for (let view of this.bindingProps()) {
      let value = object[view.binding()];

      if (typeof value === "object") {
        for (let key in value) {
          let partValue = value[key];

          if (key === "content") {
            view.node.innerHTML = partValue;
          } else {
            new pw.View(view.node).attributes().set(key, partValue);
          }
        }
      } else {
        view.node.innerHTML = value;
      }
    }

    // TODO: anything we should do if object has no id?
    this.node.setAttribute("data-id", object.id);

    return this;
  }

  transform(object) {
    if (!object || (Array.isArray(object) && object.length == 0) || Object.getOwnPropertyNames(object).length == 0) {
      this.remove();
    } else {
      for (let view of this.bindingProps()) {
        if (!object[view.binding()]) {
          new pw.View(view.node).remove();
        }
      }
    }

    return this;
  }

  present(object) {
    this.transform(object).bind(object);

    // Present recursively by finding nested bindings and presenting any we have data for.
    var bindingScopeNames = new Set(
      this.bindingScopes(true).map(
        (view) => { return view.binding(); }
      )
    );

    for (let view of bindingScopeNames) {
      if (view in object) {
        this.find(view).present(object[view]);
      }
    }

    return this;
  }

  qs (selector) {
    var results = [];

    for (let node of this.node.querySelectorAll(selector)) {
      results.push(node);
    }

    return results;
  }

  remove() {
    this.node.parentNode.removeChild(this.node);
  }

  bindings() {
    return this.bindingScopes(true).concat(this.bindingProps());
  }

  bindingScopes(includeScripts = false) {
    var bindings = [];

    this.breadthFirst(this.node, function(childNode, halt) {
      if (childNode == this.node) {
        return; // we only care about the children
      }

      if (childNode.hasAttribute("data-b") && (childNode.tagName == "SCRIPT" || new pw.View(childNode).bindingProps().length > 0)) {
        bindings.push(new pw.View(childNode));
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
          bindings.push(new pw.View(childNode));
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
          if (children[i].tagName && (includeScripts || children[i].tagName != "SCRIPT")) {
            queue.push(children[i]);
          }
        }
      }
    }
  }

  attributes() {
    return new ViewAttributes(this);
  }

  templatesNamed(name) {
    return this.qs(`script[data-b^='${name}']`).map((node) => {
      return new pw.View(node);
    });
  }

  create(insert = true) {
    var template = document.createElement("div");
    template.innerHTML = this.node.innerHTML.trim();

    var createdView = new pw.View(template.firstChild);

    if (insert) {
      this.node.parentNode.insertBefore(
        createdView.node, this.node
      );
    }

    return createdView;
  }

  use (version) {
    if (!this.match("version", version)) {
      let viewWithVersion = this.versions.find((view) => { return view.match("version", version) }).create(false);
      this.node.parentNode.replaceChild(viewWithVersion.node, this.node);
      this.node = viewWithVersion.node;
    }
  }
}
