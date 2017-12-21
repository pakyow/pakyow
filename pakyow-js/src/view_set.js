export default class {
  constructor(views, templates) {
    this.views = views;
    this.templates = this.parseTemplates(templates);
  }

  present(objects) {
    if (!Array.isArray(objects)) {
      objects = [objects];
    }

    console.log("ViewSet#present", objects, this.views, this.templates);

    if (objects.length > 0) {
      for (let view of this.views) {
        if (view.node.hasAttribute("data-empty")) {
          this.views.splice(this.views.indexOf(view), 1);
          view.node.remove();
        }

        // TODO: remove the view if there isn't a matching object
      }

      for (let object of objects) {
        var view = this.viewForObject(object)

        // TODO: we also need to build from the template in the event
        // that the current node for the object doesn't represent all
        // of the props for the object that's about to be bound

        if (!view) {
          // TODO: I feel like we should use the ViewTemplate class for this...
          var template = document.createElement("div");
          template.innerHTML = this.templates["default"].node.innerHTML;
          view = new pw.View(template.firstChild, true);
          if (this.views.length > 0) {
            this.views.slice(-1)[0].node.insertAdjacentElement("afterend", view.node)
          } else {
            this.templates["default"].node.parentNode.insertBefore(view.node, this.templates["default"].node.nextSibling);
          }
          this.views.push(view);
        }

        view.bind(object);
      }

      this.order(objects);
    } else {
      // TODO: remove everything and replace it with the empty version
    }
  }

  order (orderedObjects) {
    for (var object of orderedObjects) {
      var id = object.id;
      if (id) {
        id = id.toString();
      } else {
        return;
      }

      // TODO: look at optimizing this by not reordering unless we have to

      var match = this.views.find(function (view) {
        return view.node.getAttribute('data-id') == id;
      });

      if (match) {
        match.node.parentNode.appendChild(match.node);

        // also reorder the list of views
        var i = this.views.indexOf(match);
        this.views.splice(i, 1);
        this.views.push(match);
      }
    }
  }

  viewForObject(object) {
    // TODO: handle object not having an id

    for (let view of this.views) {
      if (view.node.getAttribute("data-id") == object.id) {
        return view;
      }
    }
  }

  parseTemplates(templates) {
    var namedTemplates = {};

    for (let template of templates) {
      var version = template.node.getAttribute("data-version")
      if (!version) {
        version = "default";
      }

      namedTemplates[version] = template;
    }

    return namedTemplates;
  }
}
