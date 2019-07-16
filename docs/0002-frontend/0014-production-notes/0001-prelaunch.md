---
title: Compiling assets during prelaunch
---

In a local development environment, Pakyow compiles and serves assets on demand. When an asset changes, the change is automatically included the next time the asset is requested. This is useful for development but isn't performant enough for a production environment.

When running in production the asset pipeline should be built before the project boots, with compiled assets served from the `public` directory. Builds can be initiated with the `pakyow assets:precompile` task.

Most projects will use the prelaunch pattern to perform all the tasks required before the project boots in production. For convenience, the precompile task is automatically added as a prelaunch command.
