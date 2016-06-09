---
name: Error Handling
desc: Handling routing errors in Pakyow.
---

Handlers are responsible for intercepting an error so that it can be handled properly. They are defined within the routes block.

Here are two basic handler definitions:

```ruby
Pakyow::App.routes do
  handler 404 do
    p 'not found'
  end

  handler 500 do
    p 'internal server error'
  end
end
```

When invoked, execution is immediately stopped, the response status code is set according to the error, and control is transferred to the handler. A handler can be invoked explicitely by calling it from a route block, hook, or another handler.

```ruby
get '/' do
  p 'foo'
  handle 404

  p 'will never see this'
end

# a GET request to '/' will print 'foo' and then 'not found' and return with a status of 404
```

There are two scenarios where a handler wil be invoked implicitly:

  1. If a request doesn't match a route, a view path, or a static file then a 404 handler will be invoked.
  2. If an exception is raised then a 500 handler will be invoked.
