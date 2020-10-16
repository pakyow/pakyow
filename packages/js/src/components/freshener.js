pw.define("freshener", {
  constructor() {
    this.listen("pw:ui:stale", () => {
      this.transition("stale");
    });
  }
});
