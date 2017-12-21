export default class {
  constructor(html, parentNode) {
    // Eventually we'll be able to replace this with
    // the HTML5 <template> tag, but not today.
    var template = document.createElement("div");
    template.innerHTML = html;
    this.node = template.firstChild;

    this.parentNode = parentNode;
  }

  create() {
    var node = this.node.cloneNode(true);
    this.parentNode.append(node);

    return new pw.View(node);
  }
}
