pw.define("form", {
  appear() {
    this.node.addEventListener("submit", (event) => {
      if (pw.ui.modifierKeyPressed) {
        return;
      }

      if (pw.server.reachable) {
        event.preventDefault();
        pw.send(event.target.action, {
          method: event.target.method,
          data: new FormData(event.target),
          success: (xhr) => {
            event.target.reset();
            pw.ui.visit(xhr.responseURL, xhr);
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
  }
});
