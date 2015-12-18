pw.component.register('fastlink', function (view, config) {
  if (window.history) {
    view.node.addEventListener('click', function (evt) {
      evt.preventDefault();
      window.history.pushState({ uri: this.href }, this.href, this.href);
      return false;
    });
  } else {
    // unsupported
  }
});
