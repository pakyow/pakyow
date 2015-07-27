(function(history) {
  var originalUri = window.location.href;

  if (history) {
    var pushState = history.pushState;
    history.pushState = function(state, title, uri) {
      if (typeof history.onpushstate == "function") {
          history.onpushstate({ state: state });
      }

      //TODO make sure socket is established, if not then
      // we have to just change the document location
      window.socket.send({
        uri: state.uri || state.url,
        action: 'call_route',
        method: 'get'
      }, function (payload) {
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
      });

      return pushState.apply(history, arguments);
    }

    window.onpopstate = function (evt) {
      var state = evt.state;

      if (!state.uri) {
        state.uri = originalUri;
      }

      history.pushState(state, state.uri, state.uri);
    }
  } else {
    // unsupported
  }
})(window.history);
