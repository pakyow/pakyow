---
name: Simple State Propagation
desc: Learn about simple state propagation.
---

Simple State Propagation is the mechanism through which Pakyow propagates
changes in state from one client to another. It prioritizes user trust and makes
it easier to reason about your program. This is best explained with an example.

Let's say we're building a comment system for a blog. When a comment is added,
we want it to show up immediately without requiring a page reload. It should
show up automatically not only for the user who created it, but for anyone else
who is currently looking at the page.

When a comment is created, Pakyow uses Simple State Propagation to tell all
clients (including the originator of the comment) how to render the new state.
It does this by building up rendering instructions that follow the View
Transformation Protocol and pushing those instructions to any clients that need
an update.

Letting the server accept state changes before rendering the change helps to
guarantee consistency. A user knows that if the comment shows up on the page,
it'll continue to show up when the page is refreshed. There's no chance of
getting into a state where one client's representation of state is ahead of the
server. Ultimate truth originates only from the One True Server.

