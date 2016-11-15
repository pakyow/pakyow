---
name: Auto-Updating Views
desc: 
---

Pakyow automatically keeps views rendered in a browser in sync with the server.
Its approach is driven entirely by server-side code and requires no JavaScript
to be written by the developer. Pakyow also avoids the complexity of
transcompiling server-side code into JavaScript, relying instead on the [View
Transformation Prototol](https://pakyow.org/docs/concepts/view-transformation-protocol).

When a view is rendered, Pakyow keeps up with the state that's being presented.
If and when the state changes, Pakyow performs a virtual re-render on the
server, serializing the rendering instructions and pushing them to each client.
Ring.js, Pakyow's client-side library, processes these instructions and updates
the DOM to reflect the new state.

Views are also progressively enhanced, meaning that if JavaScript is unavailable
for some reason, the view is still presented to the user. We believe that this
is an important step forward in how we build for the modern web.
