---
name: Middleware
desc: Using Rack middleware in Pakyow.
---

Rack middleware can be mounted at the environment level so that it's used by all
apps mounted within the environment. Pakyow loads a default stack for you:

- Rack::ContentType: Sets the `Content-Type` header on the response to
`text/html;charset=utf-8` when not explicitly set by the app.
- Rack::ContentLength: Sets the `Content-Length` header on the response.
- Rack::Head: Returns an empty body for `HEAD` requests.
- Rack::MethodOverride: Adds support for `PATCH` and `DELETE` requests through
the `_method` post parameter.
- Middleware::JSONBody: Parses json request bodies and makes the data available
as form input on the request object.
- Middleware::Normalizer: Normalizes the request to have a consistent path and
hostname.
- Middleware::Logger: Injects a request logger into the Rack object.

## Using Other Middleware

It's possible to use your own middleware. Here's an example:

```ruby
Pakyow.configure do
  use MyOwnMiddleware
end
```
