pw.component.register('mutable', function (view, config) {
  this.mutation = function (mutation) {
    var datum = pw.util.dup(mutation);
    delete datum.__nested;
    delete datum.scope;
    delete datum.id;

    var input = {};
    input[mutation.scope] = datum;

    var message = {
      action: 'call_route',
      input: input
    };

    if (view.node.tagName === 'FORM') {
      var method;
      var $methodOverride = view.node.querySelector('input[name="_method"]');
      if ($methodOverride) {
        method = $methodOverride.value;
      } else {
        method = view.node.getAttribute('method');
      }

      message.method = method;
      message.uri = view.node.getAttribute('action');
    } else {
      //TODO deduce uri / method
    }

    var self = this;
    window.socket.send(message, function (res) {
      if (res.status === 302 && res.headers.Location !== window.location.pathname) {
        var dest = res.headers.Location;
        //TODO trigger a response:redirect instead and let navigator subscribe
        history.pushState({ uri: dest }, dest, dest);
        return;
      } else if (res.status === 400) {
        // bad request
      } else {
        self.state.rollback();
      }

      pw.component.push({
        channel: 'response:received',
        payload: {
          response: res
        }
      });

      self.revert();
    });
  }
});
