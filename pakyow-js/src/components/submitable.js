pw.define("submitable", {
  constructor() {
    this.node.addEventListener("click", (event) => {
      this.node.closest("form").dispatchEvent(new CustomEvent("submit"));
    });
  }
});
