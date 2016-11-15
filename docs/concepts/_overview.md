---
name: Concepts
desc: Learn about Pakyow concepts.
---

Pakyow introduces several concepts to web development that you may not be
familiar with. These concepts include:

**View-First Development**

Pakyow enforces total separation between the presentation layer and logic of an
application. This makes the codebase clearer, improves performance, and enables
features like auto-updating views.

- [Read more about view-first development](/docs/concepts/view-first-development)

**Simple State Propagation**

Pakyow uses simple state propagation to send state changes from an originating
client to the server, then distribute the change among other connected clients.

- [Read more about simple state propagation](/docs/concepts/simple-state-propagation)

**View Transformation Protocol**

Pakyow implements a view transformation protocol to perform initial rendering on
the server and view updates on the client without a page refresh.

- [Read more the view transformation protocol](/docs/concepts/view-transformation-protocol)

