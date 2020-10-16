pw.define("form", {
  constructor() {
    this.$fields = this.view.query("input, textarea, button, select");
    this.$focused;

    // Set the element currently in focus to be refocused later.
    //
    this.enter("submitting", () => {
      $focused = document.querySelector(":focus");
    });

    // Set all fields as disabled.
    //
    this.enter("submitting", () => {
      this.disable();
    });

    // Reenable all fields when the form errors.
    //
    this.enter("failed", () => {
      this.reenable();
    });

    // Refocus on the element that was in focus before form was submitted.
    //
    this.enter("failed", () => {
      if (this.$focused) {
        this.$focused.focus();
        this.$focused = null;
      }
    });

    this.node.addEventListener("submit", (event) => {
      if (pw.ui.modifierKeyPressed) {
        return;
      }

      if (pw.server.reachable) {
        event.preventDefault();
        event.stopImmediatePropagation();

        let formData = new FormData(this.node);
        this.transition("submitting");

        // Submit the form in the background.
        //
        pw.send(this.node.action, {
          method: this.node.method,
          data: formData,
          success: (xhr) => {
            this.transition("succeeded", xhr);

            if (typeof this.config.handle_success === "undefined" || this.config.handle_success === "true") {
              if (!pw.ui.visit(xhr.responseURL, xhr)) {
                this.node.reset();
                this.reenable();
              }
            }
          },
          error: (xhr) => {
            this.transition("failed", xhr);
          }
        });

        this.transition("submitted");
      } else {
        // submit normally
      }
    });
  },

  disable() {
    this.$fields.forEach((view) => {
      view.node.disabled = true;
    });
  },

  reenable() {
    this.$fields.forEach((view) => {
      view.node.disabled = false;
    });
  }
});
