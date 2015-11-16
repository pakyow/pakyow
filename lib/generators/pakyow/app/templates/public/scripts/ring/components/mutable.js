pw.component.register('mutable', function (view, config) {
  this.mutation = function (mutation) {
    // no socket, just submit the form
    if (!window.socket) {
      view.node.submit();
      return;
    }

    var datum = pw.util.dup(mutation);
    delete datum.__nested;
    delete datum.scope;
    delete datum.id;

    var message = {
      action: 'call-route'
    };

    if (view.node.tagName === 'FORM') {
      if (view.node.querySelector('input[type="file"]')) {
        // file uploads over websocket are not supported
        view.node.submit();
        return;
      }

      var method;
      var $methodOverride = view.node.querySelector('input[name="_method"]');
      if ($methodOverride) {
        method = $methodOverride.value;
      } else {
        method = view.node.getAttribute('method');
      }

      message.method = method;
      message.uri = view.node.getAttribute('action');
      message.input = pw.node.serialize(view.node);
    } else {
      //TODO deduce uri / method

      var input = {};
      input[mutation.scope] = datum;
      message.input = input;
    }

    var self = this;
    window.socket.send(message, function (res) {
      if (res.status === 302) {
        var dest = res.headers.Location;

        if (dest == window.location.pathname && (!window.context || window.context.name !== 'default')) {
          history.pushState({ uri: dest }, dest, dest);
        } else {
          //TODO trigger a response:redirect instead and let navigator subscribe
          history.pushState({ uri: dest }, dest, dest);
        }
      } else if (res.status === 400) {
        // bad request
        return;
      } else {
        self.state.rollback();
      }

      pw.component.broadcast('response:received', { response: res });
      self.revert();
    });
  }
});
