pw.define("confirmable", {
  constructor() {
    this.message = this.config.message || "Are you sure?";

    if (this.node.tagName === "FORM") {
      this.node.addEventListener("submit", (event) => {
        this.callback(event);
      });
    } else {
      this.node.addEventListener("click", (event) => {
        this.callback(event);
      });
    }
  },

  callback(event) {
    if (confirm(this.message)) {
      // move along
    } else {
      event.preventDefault();
      event.stopImmediatePropagation();
      return false;
    }
  }
});
