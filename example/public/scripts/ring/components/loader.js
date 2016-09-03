pw.component.register('loader', function (view) {
  this.listen('socket:loading', function () {
    view.node.classList.add('ui-show');
  });

  this.listen('socket:loaded', function () {
    view.node.classList.remove('ui-show');
  });
});
