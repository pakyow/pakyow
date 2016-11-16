---
name: Mounting Endpoints
desc: Mounting Endpoints in Pakyow.
---



Multiple endpoints can be mounted in the Pakyow environment. Incoming requests
are handed to the mounted endpoints.

Here's a Pakyow App mounted at the root.

``` ruby
Pakyow.configure do
  mount Pakyow::App, at: "/"
end
```

Any `GET` requests to `/*` is passed to an instance of `Pakyow::App`

Let's create an other app and mount it.

``` ruby
class FooApp < Pakyow::App
  #empty App
end

Pakyow.configure do
  mount Pakyow::App, at: "/"
  mount FooApp, at: "/foo"
end
```


## Mount to different environments

The Pakyow object can be configured so that endpoints can be mounted in specific
environment configurations. For example, we might want to run an application
only when the environment boots in production mode. Here's an example to
illustrate how this is done.

``` ruby
Pakyow.configure :production do
  mount Pakyow::FooApp, at: "/foo"
end
```

In this example, FooApp is only mounted when the environment boots in 
production mode.

If we wanted FooApp to be mounted regardless of the environment, we 
can simply remove `:production` from the configure block.

```ruby
Pakyow.configure do
  mount Pakyow::FooApp, at: "/foo"
end
```

## Mounting Other Endpoints
Since mounting is implemented as a layer on top of `Rack::Builder`, it is possible to
mount any rack compatible endpoint. Here's an example where we mount a Sinatra
application.

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

One benefit of mounting other rack compatible endpoints such as Sinatra onto the
Pakyow environment is that it gives us consistency across all endpoints. For
example, all mounted endpoints use Pakyow's logger, and this ensures that the
logs are consistent across the board. An added benefit is that it gives all
endpoints a global way to deal with certain incoming requests such as incoming
JSON data. JSON data is parsed by the rack middleware before it is passed on to
the endpoint. Thus taking away from the responsibility from the App, because
parsing such a request should be the job of the environment.
