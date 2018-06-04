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

  binding() {
    return this.node.dataset.b;
  }

  version() {
    return this.node.dataset.v || "default";
  }

  match(property, value) {
    let propertyValue = this[property]() || "";
    value = String(value)

    if (property === "binding") {
      return propertyValue.startsWith(value);
    } else {
      return value === propertyValue;
    }
  }

  attributes() {
    return new ViewAttributes(this);
  }

  find (names) {
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

    if (found.length > 0 || templates.length > 0) {
      let set = new ViewSet(found, templates);
      if (names.length == 0) {
        return set;
      } else {
        return set.find(names);
      }
    } else {
      // FIXME: nothing was found; anything to do?
    }
  }

  bind(object) {
    this.ensureUsed();

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
      } else if(typeof value === "undefined") {
        view.remove();
      } else {
        view.node.innerHTML = value;
      }
    }

    // TODO: anything we should do if object has no id?
    this.node.dataset.id = object.id;

    return this;
  }

  transform(object, callback) {
    if (callback) {
      callback(this, object);
    }

    this.ensureUsed();

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

  use (version) {
    if (!this.match("version", version)) {
      let templateWithVersion = this.versions.find((view) => {
        return view.match("version", version)
      });

      if (templateWithVersion) {
        let viewWithVersion = templateWithVersion.clone();
        this.node.parentNode.replaceChild(viewWithVersion.node, this.node);
        this.node = viewWithVersion.node;
      } else {
        // couldn't find the version
        // FIXME: do something here?
      }
    }

    // FIXME: should we remove all known versions like on the server?

    this.used = true;
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
    var titleView = this.qs("title")[0];

    if (titleView) {
      titleView.node.innerHTML = value;
    }
  }

  //////////////////////
  // INTERNAL METHODS //
  //////////////////////

  qs (selector) {
    var results = [];

    for (let node of this.node.querySelectorAll(selector)) {
      results.push(new this.constructor(node));
    }

    return results;
  }

  bindings(includeScripts = true) {
    return this.bindingScopes(includeScripts).concat(this.bindingProps());
  }

  bindingScopes(includeScripts = false) {
    var bindings = [];

    this.breadthFirst(this.node, function(childNode, halt) {
      if (childNode == this.node) {
        return; // we only care about the children
      }

      if (
        childNode.dataset.b
        && (
          (childNode.tagName == "SCRIPT" && !childNode.dataset.p)
          || new pw.View(childNode).bindingProps().length > 0
          || new pw.View(childNode).match("version", "empty")
        )
      ) {
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

      if (childNode.dataset.b) {
        if (
          new pw.View(childNode).bindingProps().length == 0
          && !new pw.View(childNode).match("version", "empty")
        ) {
          childNode.prop = true;
          bindings.push(new pw.View(childNode));
        } else {
          halt(); // we're done here
        }
      }
    });

    return bindings;
  }

  templates() {
    if (!this.memoizedTemplates) {
      var templates = this.qs("script[type='text/template']").map((templateView) => {
        // FIXME: I think it would make things more clear to create a dedicated template object
        // we could initialize with an insertion point, then have a `clone` method there rather than on view
        let view = new pw.View(this.ensureElement(templateView.node.innerHTML));
        view.insertionPoint = templateView.node;

        // Replace bindings with templates.
        for (let binding of view.bindingProps()) {
          if (!binding.match("version", "default")) {
            let template = document.createElement("script");
            template.setAttribute("type", "text/template");
            template.dataset.b = binding.binding();
            template.dataset.v = binding.version();
            // Prevents this template from being returned by `bindingScopes`.
            template.dataset.p = true;
            template.innerHTML = binding.node.outerHTML.trim();
            binding.node.parentNode.replaceChild(template, binding.node);
          }
        }

        return view;
      });

      if (this.id()) {
        // we're looking for prop templates for a node that might have been rendered
        // on the server; look for the prop templates through the sibling scope template
        this.memoizedTemplates = new pw.View(this.node.parentNode).templates().find((template) => {
          return template.match("binding", this.binding()) && template.match("version", this.version());
        }).templates().concat(templates);
      } else {
        this.memoizedTemplates = templates;
      }
    }

    return this.memoizedTemplates;
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

  clone() {
    return new pw.View(this.node.cloneNode(true));
  }

  ensureUsed() {
    if (!this.used) {
      this.use("default");
    }
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

  setupEndpoint(endpoint) {
    var endpointView = this.findEndpoint(endpoint);

    if (endpointView) {
      let endpointActionView = this.qs("[data-e-a]")[0];

      if (!endpointActionView) {
        endpointActionView = endpointView;
      }

      if (endpointActionView.node.tagName === "A") {
        endpointActionView.node.setAttribute("href", endpoint.path);

        if (window.location.href === endpointActionView.node.href) {
          endpointView.node.classList.add("current");
        } else if (window.location.href.startsWith(endpointActionView.node.href)) {
          endpointView.node.classList.remove("current");
          endpointView.node.classList.add("active");
        } else {
          endpointView.node.classList.remove("current");
          endpointView.node.classList.remove("active");
        }
      } else {
        // unsupported
      }
    }
  }

  wrapEndpointForRemoval(endpoint) {
    var endpointView = this.findEndpoint(endpoint);

    if (endpointView) {
      let removal = document.createElement("form");
      removal.setAttribute("action", endpoint.path);
      removal.setAttribute("method", "post");
      removal.setAttribute("data-ui", "confirm");
      removal.innerHTML = '<input type="hidden" name="_method" value="delete">' + endpointView.node.outerHTML;
      endpointView.node.parentNode.replaceChild(removal, endpointView.node);
    }
  }

  findEndpoint(endpoint) {
    if (this.node.getAttribute("data-e") === endpoint.name) {
      return this;
    } else {
      return this.qs(`[data-e='${endpoint.name}']`)[0];
    }
  }
}
