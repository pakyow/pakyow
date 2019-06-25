import {default as ViewAttributes} from "./internal/view_attributes";
import {default as ViewSet} from "./internal/view_set";

export default class {
  constructor(node, versions = []) {
    this.node = node;
    this.versions = versions;
  }

  id() {
    return this.node.dataset.id;
  }

  binding(prop = false) {
    if (prop) {
      return this.node.dataset.b.split(".").pop();
    } else {
      return this.node.dataset.b;
    }
  }

  version() {
    return this.node.dataset.v || "default";
  }

  channel() {
    return this.node.dataset.c;
  }

  match(property, value) {
    let propertyValue = this[property]() || "";

    if(property === "binding") {
      value = String(value)
      return propertyValue === value || propertyValue.startsWith(value + ".");
    } else {
      value = String(value)
      return propertyValue === value;
    }

    return String(value) === this[property]() || "";
  }

  attributes() {
    return new ViewAttributes(this);
  }

  find (names, options) {
    if (!Array.isArray(names)) {
      names = [names];
    }

    names = names.slice(0);

    let currentName = names.shift();

    var templates = this.templates().filter((view) => {
      return view.match("binding", currentName);
    });

    let found = this.bindingScopes().concat(this.bindingProps()).filter((view) => {
      return view.node.tagName !== "FORM";
    }).map((view) => {
      view.versions = templates;
      return view;
    }).filter((view) => {
      return view.match("binding", currentName);
    });

    if (options) {
      if (options.id) {
        found = found.filter((view) => {
          return view.match("id", options.id);
        });
      }
    }

    if (found.length > 0 || templates.length > 0) {
      let set = new ViewSet(found, templates);
      if (names.length == 0) {
        return set;
      } else {
        return set.find(names);
      }
    }
  }

  endpoint(name) {
    if (this.node.hasAttribute("data-e")) {
      return this;
    } else {
      if (name) {
        return this.query(`[data-e='${name}']`)[0];
      } else {
        return this.query(`[data-e]`)[0];
      }
    }
  }

  endpointAction() {
    let endpointView = this.endpoint();
    return endpointView.query("[data-e-a]")[0] || endpointView;
  }

  component(name) {
    if (this.node.dataset.ui === name) {
      return this;
    } else {
      if (name) {
        return this.query(`[data-ui='${name}']`)[0];
      } else {
        return this.query(`[data-ui]`)[0];
      }
    }
  }

  bind(object) {
    if (!object) {
      return;
    }

    // Insert binding props that aren't present in the view.
    this.ensureBindingPropsForObject(object);

    for (let view of this.bindingProps()) {
      let value = object[view.binding(true)];

      if (typeof value === "object") {
        for (let key in value) {
          let partValue = value[key];

          if (key === "content") {
            if (view.node.innerHTML !== partValue) {
              view.node.innerHTML = partValue;
            }
          } else {
            new pw.View(view.node).attributes().set(key, partValue);
          }
        }
      } else if(typeof value === "undefined") {
        view.remove();
      } else {
        if (view.node.innerHTML !== value) {
          view.node.innerHTML = value;
        }
      }
    }

    this.node.dataset.id = object.id;

    return this;
  }

  transform(object, callback) {
    if (!object || (Array.isArray(object) && object.length == 0) || Object.getOwnPropertyNames(object).length == 0) {
      this.remove();
    } else {
      // Insert binding props that aren't present in the view.
      this.ensureBindingPropsForObject(object);

      // Remove binding props that aren't in the object.
      for (let view of this.bindingProps()) {
        if (!object[view.binding(true)]) {
          new pw.View(view.node).remove();
        }
      }
    }

    if (callback) {
      callback(this, object);
    }

    return this;
  }

  use(version) {
    if (!this.match("version", version)) {
      let templateWithVersion = this.versions.find((view) => {
        return view.match("version", version)
      });

      if (templateWithVersion) {
        let viewWithVersion = templateWithVersion.clone();
        this.node.parentNode.replaceChild(viewWithVersion.node, this.node);
        this.node = viewWithVersion.node;
      }
    }

    return this;
  }

  append(arg) {
    this.node.appendChild(this.ensureElement(arg));

    return this;
  }

  prepend(arg) {
    this.node.insertBefore(this.ensureElement(arg), this.node.firstChild);

    return this;
  }

  after(arg) {
    this.node.parentNode.insertBefore(this.ensureElement(arg), this.node.nextSibling);

    return this;
  }

  before(arg) {
    this.node.parentNode.insertBefore(this.ensureElement(arg), this.node);

    return this;
  }

  replace(arg) {
    this.node.parentNode.replaceChild(this.ensureElement(arg), this.node);

    return this;
  }

  remove() {
    if (this.node.parentNode) {
      this.node.parentNode.removeChild(this.node);
    }

    return this;
  }

  clear() {
    while (this.node.firstChild) {
      this.node.removeChild(this.node.firstChild);
    }

    return this;
  }

  setTitle(value) {
    var titleView = this.query("title")[0];

    if (titleView) {
      titleView.node.innerHTML = value;
    }
  }

  setHtml(value) {
    this.node.innerHTML = value;
  }

  query(selector) {
    var results = [];

    for (let node of this.node.querySelectorAll(selector)) {
      results.push(new this.constructor(node));
    }

    return results;
  }

  bindings() {
    return this.bindingScopes().concat(this.bindingProps());
  }

  bindingScopes(templates = false) {
    var bindings = [];

    this.breadthFirst(this.node, function(childNode, halt) {
      if (childNode == this.node) {
        return; // we only care about the children
      }

      if (childNode.dataset.b) {
        let childView = new pw.View(childNode);

        if ((childNode.tagName === "SCRIPT" && !childNode.dataset.p) || childView.bindingProps().length > 0 || new pw.View(childNode).match("version", "empty")) {
          // Don't descend into nested scopes.
          if (!bindings.find((binding) => { return binding.node.contains(childNode); })) {
            bindings.push(childView);
          }
        }
      }
    });

    if (templates) {
      return bindings.filter((binding) => {
        return binding.node.tagName === "SCRIPT";
      });
    } else {
      return bindings.filter((binding) => {
        return binding.node.tagName !== "SCRIPT";
      });
    }

    return bindings;
  }

  bindingProps(templates = false) {
    var bindings = [];

    this.breadthFirst(this.node, function(childNode, halt) {
      if (childNode == this.node && !String(childNode.dataset.b).includes(".")) {
        return; // we only care about the children
      }

      if (childNode.dataset.b) {
        if (childNode.dataset.b.includes(".") || (new pw.View(childNode).bindingProps().length == 0 && !new pw.View(childNode).match("version", "empty"))) {
          bindings.push(new pw.View(childNode));
        } else {
          halt(); // we're done here
        }
      }
    });

    if (templates) {
      return bindings.filter((binding) => {
        return binding.node.tagName === "SCRIPT";
      });
    } else {
      return bindings.filter((binding) => {
        return binding.node.tagName !== "SCRIPT";
      });
    }
  }

  templates() {
    var templates = this.bindingScopes(true).concat(this.bindingProps(true)).map((templateView) => {
      // FIXME: I think it would make things more clear to create a dedicated template object
      // we could initialize with an insertion point, then have a `clone` method there rather than on view
      let view = new pw.View(this.ensureElement(templateView.node.innerHTML));
      view.insertionPoint = templateView.node;

      // Replace binding scopes with templates.
      for (let binding of view.bindingScopes()) {
        let template = document.createElement("script");
        template.setAttribute("type", "text/template");
        template.dataset.b = binding.binding();
        template.dataset.v = binding.version();
        template.innerHTML = binding.node.outerHTML.trim();
        binding.node.parentNode.replaceChild(template, binding.node);
      }

      // Replace binding props with templates.
      for (let binding of view.bindingProps()) {
        let template = document.createElement("script");
        template.setAttribute("type", "text/template");
        template.dataset.b = binding.binding();
        template.dataset.v = binding.version();
        // Prevents this template from being returned by `bindingScopes`.
        template.dataset.p = true;
        template.innerHTML = binding.node.outerHTML.trim();
        binding.node.parentNode.replaceChild(template, binding.node);
      }

      return view;
    });

    if (this.id()) {
      // We're looking for prop templates for a node that might have been rendered
      // on the server; try to find the prop templates that exist in the view.
      let sibling = new pw.View(this.node.parentNode).templates().find((template) => {
        return template.match("binding", this.binding()) && template.match("version", this.version());
      });

      if (sibling) {
        templates = templates.concat(sibling.templates());
      }
    }

    return templates;
  }

  breadthFirst(node, cb) {
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
          if (children[i].tagName) {
            queue.push(children[i]);
          }
        }
      }
    }
  }

  clone() {
    return new pw.View(this.node.cloneNode(true));
  }

  ensureElement(arg) {
    if (arg instanceof Element) {
      return arg;
    } else {
      let container = document.createElement("div");
      container.innerHTML = arg.trim();
      return container.firstChild;
    }
  }

  ensureBindingPropsForObject(object) {
    for (let key in object) {
      // Skip nested data structures.
      if (object[key].constructor === Array) {
        continue;
      }

      if (!this.bindingProps().find((binding) => { return binding.match("binding", key) })) {
        let template = this.templates().find((template) => { return template.match("binding", key) });

        if (template) {
          let createdView = template.clone();
          template.insertionPoint.parentNode.insertBefore(
            createdView.node, template.insertionPoint
          );
        }
      }
    }
  }
}
