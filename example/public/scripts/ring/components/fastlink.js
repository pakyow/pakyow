pw.component.register('fastlink', function (view, config) {
  if (window.history) {
    view.node.addEventListener('click', function (evt) {
      // don't break open in new tab!
      if (evt.metaKey || evt.ctrlKey) return;

      evt.preventDefault();
      window.history.pushState({ uri: this.href }, this.href, this.href);
      return false;
    });
  } else {
    // unsupported
  }
});
