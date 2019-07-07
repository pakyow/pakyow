pw.define("form", {
  constructor() {
    let $fields = this.view.query("input, textarea, button, select");
    let $focused;

    // Set the element currently in focus to be refocused later.
    //
    this.enter("submitting", () => {
      $focused = document.querySelector(":focus");
    });

    // Set all fields as disabled.
    //
    this.enter("submitting", () => {
      $fields.forEach((view) => {
        view.node.disabled = true;
      });
    });

    // Reenable all fields.
    //
    this.leave("submitting", () => {
      $fields.forEach((view) => {
        view.node.disabled = false;
      });
    });

    // Refocus on the element in focus ahead of submitting.
    //
    this.leave("submitting", () => {
      if ($focused) {
        $focused.focus();
        $focused = null;
      }
    });

    this.node.addEventListener("submit", (event) => {
      if (pw.ui.modifierKeyPressed) {
        return;
      }

      if (pw.server.reachable) {
        event.preventDefault();
        event.stopImmediatePropagation();

        // Submit the form in the background.
        //
        pw.send(this.node.action, {
          method: this.node.method,
          data: new FormData(this.node),
          success: (xhr) => {
            this.node.reset();
            this.transition("succeeded", xhr);

            if (typeof this.config.handle_success === "undefined" || this.config.handle_success === "true") {
              pw.ui.visit(xhr.responseURL, xhr);
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
  }
});
