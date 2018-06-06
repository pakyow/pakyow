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
    }
  }

  bind(object) {
    if (!object) {
      return;
    }

    // Insert binding props that aren't present in the view.
    this.ensureBindingPropsForObject(object);

    for (let view of this.bindingProps()) {
      let value = object[view.binding()];

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
        if (!object[view.binding()]) {
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

  clean() {
    if (this.node.parentNode) {
      // Remove templates for this view so it's gone for good.
      new pw.View(this.node.parentNode).templates().forEach((template) => {
        if (template.match("binding", this.binding())) {
          template.insertionPoint.parentNode.removeChild(template.insertionPoint);
        }
      });
    }

    this.remove();

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

  query(selector) {
    var results = [];

    for (let node of this.node.querySelectorAll(selector)) {
      results.push(new this.constructor(node));
    }

    return results;
  }

  bindings(includeScripts = true) {
    return this.bindingScopes(includeScripts).concat(this.bindingProps());
  }

  // TODO: can we remove the includeScripts stuff?
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
    var templates = this.query("script[type='text/template']").map((templateView) => {
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
      let endpointActionView = this.query("[data-e-a]")[0];

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
      return this.query(`[data-e='${endpoint.name}']`)[0];
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
