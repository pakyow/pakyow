pw.component.register('notifier', function (view, config) {
  //TODO might instead register custom handlers for each; otherwise message gets hairy
  //TODO not even sure we'll use `notification:published`
  this.listen('notification:published');
  this.listen('response:received');

  view.node.addEventListener('click', function (evt) {
    view.node.classList.add('hide');
  });

  this.message = function (channel, payload) {
    if (channel === 'response:received') {
      //TODO support notification type and add a class based on it for styling
      var notification = payload.response.headers['Pakyow-Notify'];

      if (notification) {
        view.node.innerText = notification;
        view.node.classList.remove('hide');
      }
    } else if (channel === 'notification:published') {
      view.node.innerText = payload.notification;
      view.node.classList.remove('hide');
    }
  }
});
