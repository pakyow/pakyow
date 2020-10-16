pw.define("devtools", {
  constructor() {
    if (this.config.environment === "development") {
      window.localStorage.setItem(
        `pw:devtools-view-path-mapping:${this.config.viewPath}`, window.location.href
      );
    }

    this.listen("devtools:toggle-environment", () => {
      pw.send("/pw-restart?environment=" + this.switchToEnvironment(), {
        method: "post",

        success: () => {
          this.transition("restarting");
        },

        error: () => {
          console.error("[devtools] could not restart");
        }
      });
    });

    this.listen("pw:socket:connected", () => {
      if (this.state === "restarting") {
        if (this.switchToEnvironment() === "prototype") {
          window.location.assign(this.config.viewPath);
        } else {
          window.location.assign(
            window.localStorage.getItem(
              `pw:devtools-view-path-mapping:${this.config.viewPath}`
             )
          );
        }
      }
    });
  },

  switchToEnvironment() {
    if (this.config.environment === "development") {
      return "prototype";
    } else {
      return "development";
    }
  }
});

pw.define("devtools:environment", {
  constructor() {
    this.node.addEventListener("click", (event) => {
      this.bubble("devtools:toggle-environment");
    });
  }
});

pw.define("devtools:mode-selector", {
  constructor() {
    this.node.addEventListener("change", () => {
      window.location.assign(window.location.pathname + '?modes[]=' + this.node.value);
    });
  }
});

pw.define("devtools:reloader", {
  constructor() {
    this.listen("pw:ui:stale", function () {
      window.location.reload();
    });
  }
});
