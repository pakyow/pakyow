pw.component.register('modal', function (view, config, name, id) {
  var self = this;
  var channel = 'modal:' + id;
  var blinder;
  var modal;

  this.listen(channel + ':navigator:enter', function (response) {
    if (!blinder) {
      blinder = document.createElement('DIV');
      blinder.classList.add('ui-modal-blinder');

      modal = document.createElement('DIV');
      modal.classList.add('ui-modal');

      blinder.appendChild(modal);
      document.body.appendChild(blinder);

      blinder.addEventListener('click', function (evt) {
        if (evt.target === blinder) {
          evt.preventDefault();
          self.close();

          var uri = window.location.pathname;

          var opts = {
            uri: uri
          };

          window.history.pushState(opts, uri, uri);
        }
      });
    }

    modal.innerHTML = response.body;
    pw.component.findAndInit(blinder);

    blinder.classList.add('ui-appear');
  });

  this.listen(channel + ':navigator:exit', function () {
    console.log('exit');
    self.close();
  });

  this.listen(channel + ':navigator:boot', function (uri) {
    self.load(uri);
  });

  view.node.addEventListener('click', function (evt) {
    evt.preventDefault();
    self.load(this.href);
    return false;
  });

  this.load = function (uri) {
    if (!window.socket) {
      document.location = uri;
      return;
    }

    var opts = {
      uri: uri,
      context: 'modal:' + id
    }

    if (config.container) {
      opts.container = config.container;
    }

    window.history.pushState(opts, uri, uri);
  };

  this.close = function () {
    pw.node.remove(blinder);
    blinder = null;
    modal = null;
  };
});
