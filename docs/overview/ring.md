---
name: Ring.js Components
desc: "Ring.js: Pakyow on the client."
---

Ring.js is Pakyow's client-side JavaScript library. It enables features like
auto-updating views by implementing a client-side version of the view
transformation protocol. This allows Ring to receive view transformations and
apply them to the rendered DOM.

Ring also provides tools for building frontend components. Components are
responsible for enabling a particular user interaction and telling the server
about interactions that happen. In most cases, *components never know about or
manage state.*

Components can communicate with the server over a WebSocket connection. For
example, a backend route can be called asyncronously over the WebSocket. These
calls require less overhead and are thus much faster than identical calls with
AJAX & HTTP. The server can also push messages to a component, providing an easy
way to present notifications to a user or update a progress bar in realtime.

Ring.js is also a small library with no dependencies, weighing in at 23KB.

- [Browse the Ring.js source on GitHub](https://github.com/pakyow/ring)
