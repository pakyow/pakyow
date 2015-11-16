pw.component.register('modal', function (view, config, name, id) {
  var self = this;
  var channel = 'modal:' + id;
  var blinder, modal;
  var blinderTemplate;

  if (blinderTemplate = document.querySelector('*[data-template="ui-modal-blinder"]')) {
    blinderTemplate = blinderTemplate.cloneNode(true);
  }

  this.listen(channel + ':navigator:enter', function (response) {
    if (!blinder) {
      if (blinderTemplate) {
        blinder = blinderTemplate.cloneNode(true);
        modal = blinder.querySelector('*[data-template="ui-modal-content"]');
        document.body.appendChild(blinder);

        blinder.removeAttribute('data-template');
        modal.removeAttribute('data-template');
      } else {
        blinder = document.createElement('DIV');
        blinder.classList.add('ui-modal-blinder');

        modal = document.createElement('DIV');
        modal.classList.add('ui-modal');

        blinder.appendChild(modal);
        document.body.appendChild(blinder);
      }

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

    if (config.partial) {
      opts.partial = config.partial;
    }

    window.history.pushState(opts, uri, uri);
  };

  this.close = function () {
    if (!blinder || !modal) {
      return;
    }

    pw.node.remove(blinder);
    blinder = null;
    modal = null;
  };
});
