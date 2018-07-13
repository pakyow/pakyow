import {default as ViewSetAttributes} from "./view_set_attributes";

export default class {
  constructor(views, templates) {
    this.views = views;
    this.templates = templates;
  }

  find(names) {
    if (!Array.isArray(names)) {
      names = [names];
    }

    var views = [], templates = [];

    for (let view of this.views) {
      let found = view.find(names);
      views = views.concat(found.views);

      if (!templates) {
        templates = views.templates();
      }
    }

    for (let template of this.templates) {
      templates = templates.concat(
        template.templates().filter((view) => {
          for (let name of names) {
            if (view.match("binding", name)) {
              return true;
            }
          }
        })
      );
    }

    return new this.constructor(views, templates);
  }

  bind(objects) {
    if (!Array.isArray(objects)) {
      objects = [objects];
    }

    for (let object of objects) {
      this.ensureViewForObject(object).bind(object)
    }

    return this;
  }

  transform(objects, callback) {
    if (!Array.isArray(objects)) {
      objects = [objects];
    }

    if (objects.length > 0) {
      for (let object of objects) {
        this.ensureViewForObject(object).transform(object, callback);
      }

      for (let view of this.views) {
        // Remove the view if it's an empty version, since we now have data.
        if (view.match("version", "empty")) {
          this.views.splice(this.views.indexOf(view), 1);
          view.remove();
          continue;
        }

        // Remove the view if we can't find an object with its id.
        if (!objects.find((object) => { return view.match("id", object["id"]) } )) {
          this.views.splice(this.views.indexOf(view), 1);
          view.remove();
        }
      }

      this.order(objects);
    } else {
      let template = this.templates.find((template) => {
        return template.version() === "empty"
      });

      if (template) {
        let createdView = template.clone();
        template.insertionPoint.parentNode.insertBefore(
          createdView.node, template.insertionPoint
        );
      }

      for (let view of this.views) {
        view.remove();
      }
    }

    return this;
  }

  use(version) {
    for (let view of this.views) {
      view.use(version);
    }

    this.usableVersion = version;

    return this;
  }

  clean() {
    this.views.forEach((view) => {
      view.clean();
    });

    return this;
  }

  attributes() {
    return new ViewSetAttributes(this);
  }

  order (orderedObjects) {
    if (this.views.length == 0) {
      return;
    }

    let orderedIds = orderedObjects.map((object) => {
      return object.id;
    });

    // Make sure the first view is correct.
    let firstMatch = this.viewWithId(orderedIds[0]);
    if (!this.views[0].match("id", orderedIds[0])) {
      firstMatch.node.parentNode.insertBefore(firstMatch.node, this.views[0].node);

      // Update `this.views` to match.
      this.views.splice(this.views.indexOf(firstMatch), 1);
      this.views.unshift(firstMatch);
    }

    // Now move the others into place.
    let currentMatch = firstMatch;
    for (let i = 0; i < orderedIds.length; i++) {
      let nextMatchId = orderedIds[i];
      let nextMatch = this.viewWithId(nextMatchId);

      if (!this.views[i].match("id", nextMatchId)) {
        nextMatch.node.parentNode.insertBefore(nextMatch.node, currentMatch.node.nextSibling);

        // Update `this.views` to match.
        this.views.splice(this.views.indexOf(nextMatch), 1);
        this.views.splice(this.views.indexOf(currentMatch), 0, nextMatch);
      }

      currentMatch = nextMatch;
    }

    return this;
  }

  append(arg) {
    this.views.forEach((view) => {
      view.append(arg);
    });

    return this;
  }

  prepend(arg) {
    this.views.forEach((view) => {
      view.prepend(arg);
    });

    return this;
  }

  after(arg) {
    this.views.forEach((view) => {
      view.after(arg);
    });

    return this;
  }

  before(arg) {
    this.views.forEach((view) => {
      view.before(arg);
    });

    return this;
  }

  replace(arg) {
    this.views.forEach((view) => {
      view.replace(arg);
    });

    return this;
  }

  remove() {
    this.views.forEach((view) => {
      view.remove();
    });

    return this;
  }

  clear() {
    this.views.forEach((view) => {
      view.clear();
    });

    return this;
  }

  viewWithId(id) {
    return this.views.find(function (view) {
      return view.match("id", id);
    });
  }

  viewForObject(object) {
    return this.viewWithId(object.id);
  }

  viewHasAllBindings(view, object) {
    for (let key in object) {
      if (key === "id") {
        continue;
      }

      if (!view.bindings().find((view) => { return view.match("binding", key) })) {
        return false;
      }
    }

    return true;
  }

  ensureViewForObject(object) {
    var view = this.viewForObject(object);

    if (!view) {
      let template = this.templates.find((template) => {
        return template.match("version", this.usableVersion || "default")
      });

      if (!template) {
        template = this.templates.filter((template) => {
          return !template.match("version", "empty");
        })[0];
      }

      let createdView = template.clone();

      if (this.views.length == 0) {
        template.insertionPoint.parentNode.insertBefore(
          createdView.node, template.insertionPoint
        );
      } else {
        let lastView = this.views[this.views.length - 1];
        lastView.node.parentNode.insertBefore(
          createdView.node, lastView.node.nextSibling
        );
      }

      view = new pw.View(createdView.node, this.templates);
      this.views.push(view);
    } else if (!this.viewHasAllBindings(view, object)) {
      // Replace the current view with a fresh version.

      let template = this.templates.find((template) => {
        return template.match("version", this.usableVersion || "default")
      });

      if (!template) {
        // if we don't have a default version, use the first one
        template = this.templates[0];
      }

      var freshView = template.clone();
      freshView.node.dataset.id = object.id;
      freshView.versions = this.templates;
      this.views[this.views.indexOf(view)] = freshView;
      view.node.parentNode.replaceChild(freshView.node, view.node);
      view = freshView;
    }

    return view;
  }
}
