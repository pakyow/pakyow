import {default as ViewSetAttributes} from "./view_set_attributes";

export default class {
  constructor(views, templates) {
    this.views = views;
    this.templates = templates;
  }

  present(objects, callback) {
    if (!Array.isArray(objects)) {
      objects = [objects];
    }

    if (objects.length > 0) {
      for (let view of this.views) {
        // Remove the view if it's an empty version, since we now have data.
        if (view.match("version", "empty")) {
          this.views.splice(this.views.indexOf(view), 1);
          view.remove();
          continue;
        }

        // Remove the view if we can't find an object with its id.
        if (!objects.find((object) => { return view.match("id", object["id"]) } )) {
          view.node.remove();
          // Update `this.views` to match.
          this.views.splice(this.views.indexOf(view), 1);
        }
      }

      for (let object of objects) {
        var view = this.viewForObject(object);

        if (!view) {
          let template = this.templates.find((template) => {
            return template.match("version", "default")
          });

          if (!template) {
            // If we don't have a default version, use the first non-empty one.
            template = this.templates.filter((template) => {
              return !template.match("version", "empty");
            })[0];
          }

          view = new pw.View(template.create().node, this.templates);
          this.views.push(view);

          // create templates for any nested bindings
          // for (let binding of view.bindingScopes()) {
          //   var bindingTemplate = document.createElement("script");
          //   bindingTemplate.setAttribute("type", "text/template");
          //   bindingTemplate.setAttribute("data-v", binding.node.getAttribute("data-v") || "default");
          //   bindingTemplate.setAttribute("data-b", binding.node.getAttribute("data-b"));
          //   bindingTemplate.appendChild(binding.node.cloneNode(true));
          //   view.node.appendChild(bindingTemplate);
          // }

          // if (this.views.length > 0) {
          //   this.views.slice(-1)[0].node.insertAdjacentElement(
          //     "afterend", view.node
          //   );
          // } else {
          //   this.templates["default"].view.node.parentNode.insertBefore(
          //     view.node, this.templates["default"].node
          //   );
          // }
        } else if (!this.viewHasAllBindings(view, object)) {
          // Replace the current view with a fresh version.

          let template = this.templates.find((template) => {
            return template.match("version", "default")
          });

          if (!template) {
            // if we don't have a default version, use the first one
            template = this.templates[0];
          }

          var freshView = template.create(false);
          this.views[this.views.indexOf(view)] = freshView;
          view.node.parentNode.insertBefore(freshView.node, view.node);
          view.remove();

          view = new pw.View(freshView.node, this.templates);
        }

        if (callback) {
          callback(view, object);
        }

        view.present(object);
      }

      this.order(objects);
    } else {
      let template = this.templates.find((template) => {
        return template.version() === "empty"
      });

      if (template) {
        template.create();
      }

      for (let view of this.views) {
        view.remove();
      }
    }
  }

  use(version) {
    // Use the version in each view.
    for (let view of this.views) {
      view.use(version);
    }

    // Delete templates that aren't the used version.
    for (let template of this.templates.slice()) {
      if (!template.match("version", version)) {
        this.templates.splice(this.templates.indexOf(template), 1);
      }
    }
  }

  attributes() {
    return new ViewSetAttributes(this);
  }

  order (orderedObjects) {
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

      if ( !view.bindings().find((view) => { return view.match("binding", key) })) {
        return false;
      }
    }

    return true;
  }
}
