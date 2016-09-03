---
name: Routing
desc: Routing requests in Pakyow.
---

Routes are responsible for routing a request to back-end logic. In Pakyow, a route consists of:

  1. HTTP method (GET, PUT, POST, PATCH, DELETE)
  2. Pattern to match request path
  3. Route function(s)
  4. Name (optional)

This is one of the simplest route definitions:

```ruby
get '/' do
  p 'got it'
end

# sending a GET request to '/' prints 'got it' to the log
```

Defining routes for the other supported HTTP methods is just as easy:

```ruby
put '/' do
  p 'put'
end

post '/' do
  p 'post'
end

patch '/' do
  p 'patch'
end

delete '/' do
  p 'delete'
end
```

Routes should be defined inside an app's `routes` block (in a generated app, this is in `app/lib/routes.rb`).

```ruby
Pakyow::App.routes do
  get '/' do
    p 'got it'
  end

  # other routes here
end
```

## Route Arguments

Named arguments can be defined for a route. When the route is matched, data will be parsed from the incoming request and available in the back-end logic through the `params` helper.

```ruby
get 'say/:msg' do
  p params[:msg]
end

# sending a GET request to '/say/hello' prints 'hello' to the log
```

## Named Routes

Routes can be given an optional name.

```ruby
get :root, '/' do
  # ...
end
```

This name is used to look up and populate routes URIs.

## Default Route

For convenience, a default route can be defined without providing a path.

```ruby
default do
  # ...
end
```

This is identical to defining a `get` route for `/` with a name of `:default`.

```ruby
get :default, '/' do
  # ...
end
```

## Regex Matchers

In addition to string matchers, regex is also supported.

```ruby
# match anything
get /.*/ do
  # ...
end
```

Named captures (available since ruby-1.9) are also supported. When matched, data will be available just like with a route argument.

```ruby
get /say\/(?<msg>(.*))/ do
  p params[:msg]
end

# sending a GET request to '/say/hello' prints 'hello' to the log
```
