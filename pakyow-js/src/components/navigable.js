pw.define("navigable", {
  appear() {
    this.headDetails = this.buildHeadDetails(document.head);
    this.initialState = { url: document.location.pathname, scrollX: 0, scrollY: 0 };

    if ("scrollRestoration" in window.history) {
      history.scrollRestoration = "manual";
    }

    window.onpopstate = (event) => {
      this.load(event.state || this.initialState);
    };

    this.modifierKeyPressed = false;

    document.documentElement.addEventListener("keydown", (event) => {
      if (event.metaKey || event.crtlKey || event.altKey || event.shiftKey) {
        this.modifierKeyPressed = true;
      }
    });

    document.documentElement.addEventListener("keyup", (event) => {
      if (!event.metaKey && !event.crtlKey && !event.altKey && !event.shiftKey) {
        this.modifierKeyPressed = false;
      }
    });

    document.documentElement.addEventListener("click", (event) => {
      if (this.modifierKeyPressed) {
        return;
      }

      let link = event.target.closest("a");

      if (link) {
        event.preventDefault();
        this.visit(link.href);
      }
    });

    document.documentElement.addEventListener("submit", (event) => {
      if (this.modifierKeyPressed) {
        return;
      }

      if (pw.server.reachable) {
        event.preventDefault();
        pw.send(event.target.action, {
          method: event.target.method,
          data: new FormData(event.target),
          success: (xhr) => {
            event.target.reset();
            this.visit(xhr.responseURL, xhr);
          },
          complete: (xhr) => {
            $fields.forEach((view) => {
              view.node.disabled = false;
            });

            if ($focused) {
              $focused.focus();
              $focused = null;
            }
          }
        });

        let $focused = document.querySelector(":focus");
        let $fields = new pw.View(event.target).query("input, textarea, button, select");
        $fields.forEach((view) => {
          view.node.disabled = true;
        });
      } else {
        // submit normally
      }
    });
  },

  visit(url, xhr) {
    if (this.isCurrent(url)) {
      return;
    }

    if (window.history && this.isInternal(url)) {
      this.saveScrollPosition();

      var state = { url: url, scrollX: 0, scrollY: 0 };
      window.history.pushState(state, "", url);

      if (xhr) {
        this.handleXHR(xhr, state)
      } else {
        this.load(state);
      }
    } else {
      document.location = url;
    }
  },

  load(state) {
    var xhr = pw.send(state.url, {
      complete: (xhr) => {
        this.handleXHR(xhr, state);
      },

      progress: (event) => {
        let value;

        if(event.total) {
          value = event.loaded / event.total;
        }

        if (value < 1) {
          pw.broadcast("navigator:progressed", { id: xhr.id, value: value });
        }
      }
    });

    pw.broadcast("navigator:dispatched", { id: xhr.id });
  },

  handleXHR(xhr, state) {
    let doc = document.documentElement.cloneNode();
    doc.innerHTML = xhr.responseText;

    let newHeadDetails = this.buildHeadDetails(doc.querySelector("head"));

    let loadables = [];

    // Add new scripts to be loaded.
    // Creating a new element is the only way to get the onload callback to fire.
    Object.keys(newHeadDetails.scripts).forEach((key) => {
      if (!this.headDetails.scripts[key]) {
        var script = new pw.View(document.createElement("script"));
        script.node.setAttribute("src", newHeadDetails.scripts[key].node.src);
        newHeadDetails.scripts[key] = script;
        loadables.push(script);
      }
    });

    // Add new styles to be loaded.
    Object.keys(newHeadDetails.styles).forEach((key) => {
      if (!this.headDetails.styles[key]) {
        loadables.push(newHeadDetails.styles[key]);
      }
    });

    this.loadExternals(loadables, xhr, () => {
      // Insert new non-scripts/styles.
      newHeadDetails.others.forEach((view) => {
        document.head.appendChild(view.node);
      });

      // Remove current non-scripts/styles.
      this.headDetails.others.forEach((view) => {
        view.remove();
      });

      // Remove old scripts.
      Object.keys(this.headDetails.scripts).forEach((key) => {
        if (!newHeadDetails.scripts[key]) {
          this.headDetails.scripts[key].remove();
        } else {
          newHeadDetails.scripts[key] = this.headDetails.scripts[key];
        }
      });

      // Remove old styles.
      Object.keys(this.headDetails.styles).forEach((key) => {
        if (!newHeadDetails.styles[key]) {
          this.headDetails.styles[key].remove();
        } else {
          newHeadDetails.styles[key] = this.headDetails.styles[key];
        }
      });

      this.headDetails = newHeadDetails;

      // Replace the current body with the one that was just requested.
      document.documentElement.replaceChild(doc.querySelector("body"), document.body);

      // Scroll to the correct position.
      window.scrollTo(state.scrollX, state.scrollY);

      pw.broadcast("navigator:changed", { id: xhr.id });
    });
  },

  isInternal(url) {
    var link = document.createElement("a");
    link.href = url;

    return link.host === window.location.host && link.protocol === window.location.protocol;
  },

  isCurrent(url) {
    var link = document.createElement("a");
    link.href = url;

    return this.isInternal(url) && link.pathname === window.location.pathname;
  },

  buildHeadDetails(head) {
    let details = {
      scripts: {}, styles: {}, others: []
    };

    new pw.View(head).query("*").forEach((view) => {
      if (view.node.tagName === "SCRIPT" && view.node.src) {
        details.scripts[view.node.outerHTML] = view;
      } else if (view.node.tagName === "LINK" && view.node.rel === "stylesheet" && view.node.href) {
        details.styles[view.node.outerHTML] = view;
      } else {
        details.others.push(view);
      }
    });

    return details;
  },

  loadExternals(loadables, xhr, callback) {
    if (loadables.length > 0) {
      let loading = [];
      loadables.forEach((view) => {
        loading.push(view);

        view.node.onload = () => {
          loading.splice(loading.indexOf(view), 1);

          let total = loadables.length + 1;
          let loaded = total - loading.length;
          pw.broadcast("navigator:progressed", {id: xhr.id, value: loaded / total });

          if (loading.length === 0) {
            callback();
          }
        };

        document.head.appendChild(view.node);
      });
    } else {
      pw.broadcast("navigator:progressed", {id: xhr.id, value: 1 });
      callback();
    }
  },

  saveScrollPosition() {
    if (window.history.state) {
      window.history.state.scrollX = window.pageXOffset;
      window.history.state.scrollY = window.pageYOffset;
      window.history.replaceState(window.history.state, "", window.history.state.url);
    } else {
      this.initialState.scrollX = window.pageXOffset;
      this.initialState.scrollY = window.pageYOffset;
    }
  }
});

pw.define("navigator:progress", {
  appear() {
    this.listen("navigator:dispatched", (state) => {
      if (!this.current) {
        this.current = state.id;
        this.node.style.width = 0.0;

        this.timeout = setTimeout(() => {
          this.show();
        }, 300);
      }
    });

    this.listen("navigator:changed", (state) => {
      if (this.current === state.id) {
        if (this.timeout) {
          clearTimeout(this.timeout);
          this.timeout = null;
        }

        this.current = null;
        this.hide();
      }
    });

    this.listen("navigator:progressed", (state) => {
      if (this.current === state.id) {
        this.node.style.width = state.value * 100 + "%";
      }
    });
  },

  show() {
    this.node.style.opacity = 1.0;
  },

  hide() {
    this.node.style.opacity = 0.0;
  }
});
