---
name: Environment
desc: Define, mount, and run multiple Ruby apps in a consistent environment.
---

The Pakyow Environment makes it possible to define, mount, and run multiple apps
inside of a single process. It's quite simple both in theory and implementation,
but it carries some big advantages.

Perhaps the biggest advantage being that the environment is consistent across
apps that run within it. For example, every app runs on the same host and port
and inherits a common request logger.

Pakyow also loads a default middleware stack for every app running within the
environment. Without explicit configuration, all endpoints support things like
HEAD requests and JSON request bodies &emdash; things that most apps need.

Pakyow effectively separate the concerns of the *app* from the concerns of the
*environment* that runs the app. This is admittedly a subtle distinction, but
the consistency it brings to developing and running Ruby apps is quite nice.
