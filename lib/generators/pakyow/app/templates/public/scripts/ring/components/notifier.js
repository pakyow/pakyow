pw.component.register('notifier', function (view, config) {
  this.listen('notification:published', function (payload) {
    view.node.innerText = payload.notification;
    view.node.classList.remove('hide');
  });

  this.listen('response:received', function (payload) {
    //TODO support notification type and add a class based on it for styling
    var notification = payload.response.headers['Pakyow-Notify'];

    if (notification) {
      view.node.innerText = notification;
      view.node.classList.remove('hide');
    }
  });

  view.node.addEventListener('click', function (evt) {
    view.node.classList.add('hide');
  });
});
