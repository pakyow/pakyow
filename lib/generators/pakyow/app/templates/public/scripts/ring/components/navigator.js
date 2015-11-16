function boot() {
  if (!window.socket) {
    setTimeout(boot, 100);
    return;
  }

  if (window.location.hash) {
    var arr = window.location.hash.split('#:')[1].split('/');
    var context = arr.shift();
    var uri = arr.join('/');

    pw.component.broadcast(context + ':navigator:boot', uri);
  }
}

(function(history) {
  pw.init.register(boot);

  if (history) {
    var hasPushed = false;
    var pushState = history.pushState;

    history.pushState = function(state, title, uri) {
      hasPushed = true;

      if (typeof history.onpushstate == "function") {
        history.onpushstate({ state: state });
      }

      if (uri == window.location.pathname) {
        pw.component.broadcast(window.context.name + ':navigator:exit');

        window.context = {
          _state: state,
          name: 'default',
          uri: window.location.href
        };

        state.r_uri = uri;
      } else {
        handleState(state, 'forward');
      }

      return pushState.apply(history, [state, title, state.r_uri]);
    }

    window.onpopstate = function (evt) {
      if (!hasPushed) {
        return;
      }

      var state = evt.state;

      if (!state) {
        state = {};
      }

      if (!state.uri) {
        state.uri = window.context.uri;
      }

      handleState(state, 'back');
    }
  } else {
    // unsupported
  }
})(window.history);

window.context = {
  name: 'default',
  uri: window.location.href
};

function handleState(state, direction) {
  var uri = state.uri || state.url;

  // socket isn't ready, so just send 'em to the url
  if (!window.socket) {
    document.location = uri;
    return;
  }

  if (state.context) {
    state.r_uri = document.location.pathname + '#:' + state.context + '/' + uri;

    window.context = {
      _state: state,
      name: state.context,
      uri: state.r_uri,
      container: state.container,
      partial: state.partial
    };
  } else {
    state.r_uri = uri;

    if (window.context.name !== 'default') {
      if (direction === 'back') {
        // we are leaving a context
        pw.component.broadcast(window.context.name + ':navigator:exit');

        window.context = {
          name: 'default',
          uri: state.uri
        };

        return;
      } else {
        // navigate in context
        state.r_uri = document.location.pathname + '#:' + window.context.name + '/' + uri;
        state.context = window.context.name;
        state.container = window.context.container;
        state.partial = window.context.partial;
      }
    }
  }

  var opts = {
    uri: uri,
    action: 'call-route',
    method: 'get'
  };

  if (state.container) {
    opts.container = state.container;
  }

  if (state.partial) {
    opts.partial = state.partial;
  }

  window.socket.send(opts, function (payload) {
    if (state.context) {
      pw.component.broadcast(state.context + ':navigator:enter', payload);
    } else {
      var body = payload.body[0];

      if (body.match(/<title>/)) {
        document.title = body.split(/<title>/)[1].split('</title>')[0];
      }

      if (body.match(/<body [^>]*>/)) {
        document.body.innerHTML = body.split(/<body [^>]*>/)[1].split('</body>')[0];
      } else {
        document.body.innerHTML = body;
      }

      pw.component.findAndInit(document.querySelectorAll('body')[0]);
    }
  });
}
