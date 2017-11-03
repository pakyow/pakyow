---
name: Mounting Apps
desc: Mounting apps as endpoints in Pakyow.
---

Apps can be mounted at various paths within the Pakyow environment. Incoming
requests that match the mount path are routed to the endpoint.

Here's an example:

``` ruby
Pakyow.configure do
  mount Pakyow::App, at: "/"
end
```

Any `GET` request to `/*` is routed to an instance of `Pakyow::App`.

Let's create another app and mount it at a different path:

``` ruby
class FooApp < Pakyow::App
end

Pakyow.configure do
  mount Pakyow::App, at: "/"
  mount FooApp, at: "/foo"
end
```

## Mode-Specific Mounting

The Pakyow environment can be configured so that endpoints are only used when
the environment is started in a specific mode. For example, we might want to
run an application in development mode, but ignore it in production. Here's
an example that illustrates this feature:

``` ruby
Pakyow.configure :development do
  mount Pakyow::FooApp, at: "/foo"
end
```

In the above example, `FooApp` is only mounted when the environment boots in 
`development` mode. If we want `FooApp` to be mounted regardless of the mode,
we can simply remove the mode from the `configure` block:

```ruby
Pakyow.configure do
  mount Pakyow::FooApp, at: "/foo"
end
```

## Mounting Other Endpoints

Since mounting is implemented as a layer on top of `Rack::Builder`, it's possible to
mount any Rack-compatible endpoint. Here's an example where we mount a Sinatra app:

```ruby 
require "sinatra/base"

class SinatraApp < Sinatra::Base
  get "/" do
    "hello"
  end
end

Pakyow.configure do
  mount SinatraApp, at: "/"
end
```

The benefit to this is that we can run all our Ruby apps in a consistent way. Every
app in the environment runs on the same host and port and inherits a common request
logger. Pakyow also loads a default middleware stack for every app running within
the environment. Without explicit configuration, all apps support common things like 
HEAD requests and JSON request bodies.
