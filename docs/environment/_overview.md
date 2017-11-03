---
name: Environment
desc: Define, mount, and run multiple Ruby apps in a consistent environment.
---

Pakyow provides a consistent environment in which to define, mount, and run
multiple apps &emdash; all within a single process. The Pakyow environment can
run any app that's compatible with the Rack interface, including those built
using frameworks like Sinatra, Roda, and Hanami.

Every app in the environment runs on the same host and port and inherits a
common request logger. Pakyow also loads a default middleware stack for every
app running within the environment. Without explicit configuration, all apps
support common things like HEAD requests and JSON request bodies.

Pakyow effectively separates the concerns of the *app* from the concerns of the
*environment* that runs the app. This is admittedly a subtle distinction, but
the consistency it brings to developing and running Ruby apps is quite nice.
