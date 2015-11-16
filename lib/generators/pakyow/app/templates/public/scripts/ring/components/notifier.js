pw.component.register('notifier', function (view, config) {
  var that = this;

  this.listen('notification:published', function (payload) {
    that.show(payload.notification);
  });

  this.listen('response:received', function (payload) {
    //TODO support notification type and add a class based on it for styling
    var notification = payload.response.headers['Pakyow-Notify'];

    if (notification) {
      that.show(notification);
    }
  });

  view.node.addEventListener('click', function (evt) {
    view.node.classList.add('hide');
  });

  this.message = function (channel, payload) {
    that.show(payload.notification);
  };

  this.show = function (notification) {
    view.node.innerText = notification;
    view.node.classList.remove('hide');
  };
});
