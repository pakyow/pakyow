---
name: Simple State Propagation
desc: Learn about simple state propagation.
---

Simple State Propagation is how Pakyow propagates state changes from one client
to another. It allows us to prioritize user trust while making our code faster
to write and easier to maintain.

Let's say you're building a comment system. When a comment is added, users
should see it immediately without having to reload the page. The new comment
should also show up for other users who are currently looking at the page.

Pakyow handles both cases automatically. It accomplishes this by building up
rendering instructions and pushing them through a WebSocket to the originating
client and any other client that requires an update.

*State changes aren't rendered by any client, including the originator, until the
backend has validated and persisted the change.* This is an important
implementation detail that helps to guarantee consistency and is part of
[prioritizing user trust](/docs/overview/prioritized-user-trust).

Requiring the server accept state changes before rendering the change helps to
guarantee consistency. Without this guarantee, users have no way to know that
what they see is reality. This can come back to bite users if, after refreshing,
they see state they didn't see before.

**In Pakyow, ultimate truth originates only from the One True Server.**
