---
name: Mounting Endpoints
desc: Mounting Endpoints in Pakyow
---

#2.1 Basic pakyow example


The Pakyow runtime environment makes it possible to define, mount and run multiple applications in the same process.

Here’s an example of a simple Pakyow App:

``` ruby
class FooApp < Pakyow::App
  router do
    get "/" do
      send "foo"
    end
  end
end
```

FooApp simply returns the string “foo”. To test this out run this command in the terminal.

`curl http://localhost:3000/ && echo`

To mount the application we use the Pakyow object to configure the environment and mount the FooApp at the root path. Here’s what that looks like:

``` ruby
Pakyow.configure do
    mount FooApp, at: "/"
end
```

Next, we setup and run our environment in development mode.

``` ruby
Pakyow.setup(:development).run
```

Now, let’s create and mount another application.

``` ruby
class BarApp < Pakyow::App
  router do
    get "/" do
      send "bar"
    end
  end
end
```

We mount the new application at “/bar”.

``` ruby
Pakyow.configure do
    mount FooApp, at: "/"
	  mount BarApp, at: "/bar"
end
```

Running `curl http://localhost:3000/bar && echo` will print the string “bar” to the terminal.



#2.2 Environment-specific mounting

The Pakyow object can be configured so that endpoints can be mounted in specific environment configurations. For example, we might want to run an application only when the environment boots in production mode. Here’s an example to illustrate how this is done.

``` ruby
Pakyow.configure :production do
  mount Pakyow::FooApp, at: "/foo"
end
```

In this example, FooApp is only mounted when the environment boots in production mode.

If we wanted FooApp to be mounted regardless of the environment, we can simply remove

``` ruby
:production
```
from the configure block.

```ruby
Pakyow.configure do
  mount Pakyow::FooApp, at: “/foo”
end
```

#2.3 Other rack-compatible endpoints
Since mounting is implemented as a layer on top of `Rack::Builder`, it is possible to mount any rack compatible endpoint. Here’s an example where we mount a Sinatra application.

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
