---
name: Tools
desc: Tools for building Pakyow projects.
---

Pakyow provides several tools useful during development.

## Server

The server command runs a local instance of a Pakyow application.

```
pakyow server [environment]
```

If environment is not specified, the `default_environment` defined in the application will be used.

When starting the server, Pakyow will try the following handlers in order:

  - puma
  - thin
  - mongrel
  - webrick

You can run a specific handler by setting the `server.handler` [config option](/docs/config).

> Elsewhere in this documentation, you'll always see pakyow server executed like this:
>
>```
>bundle exec pakyow server [environment]
>```
>
>The reasons for this are laid out on the [Bundler home page](http://bundler.io/ "Bundler home page"):
>
>>In some cases, running executables without `bundle exec` may work, if the executable happens to be installed in your system and does not pull in any gems that conflict with your bundle.
>>
>>However, this is unreliable and is the source of considerable pain. Even if it looks like it works, it may not work in the future or on another machine.

## Console

The console command loads an application into a REPL (like IRB).

```
pakyow console [environment]
```

If environment is not specified, the `default_environment` defined in the app will be used. Once started, you can execute Ruby code against your app. If a file is changed, the session can be reloaded, like so:

```
reload
Reloading...
```

## Rake Tasks

Several rake tasks are included with the `pakyow-rake` gem. To use them, add `pakyow-rake` to your `Gemfile` and require it at the top of `Rakefile`. Here's a list of tasks it adds to your app:

```
rake --tasks
rake pakyow:bindings[view_path]  # List bindings across all views, or a specific view path
rake pakyow:prepare              # Prepare the app by configuring and loading code
rake pakyow:routes               # List all routes (method, path, group[name])
rake pakyow:stage                # Stage the app by preparing and loading routes / views
```
