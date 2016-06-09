---
name: Concepts
desc: Learn about Pakyow concepts.
---

Pakyow introduces several new concepts to the web development space.

**View-First Development**

Pakyow enforces total separation between the presentation layer and logic of an
application. This makes the codebase clearer, improves performance, and enables
features such as auto-updating views.

- [Read more about view-first development](/docs/concepts/view-first-development)

**Simple State Propagation**

Pakyow uses simple state propagation to send state changes from an originating
client to the server, then distribute the change among other connected clients.

- [Read more about simple state propagation](/docs/concepts/simple-state-propagation)

**View Transformation Protocol**

Pakyow implements the view transformation protocol to perform initial rendering
on the server and in Ring.js for client-side updates without a refresh.

- [Read more the view transformation protocol](/docs/concepts/view-transformation-protocol)

