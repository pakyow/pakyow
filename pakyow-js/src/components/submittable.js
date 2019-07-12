pw.define("submittable", {
  constructor() {
    this.node.addEventListener("click", (event) => {
      event.preventDefault();
      event.stopImmediatePropagation();
      this.node.closest("form").submit();
    });
  }
});
