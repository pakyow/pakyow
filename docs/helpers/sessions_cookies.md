---
name: Sessions & Cookies
desc: Using sessions and cookies.
---

Sessions keep state across requests. They can be enabled by using any Rack session middleware (defined in `app.rb`):

```ruby
middleware do |builder|
  builder.use Rack:Session::Cookie
end
```

Once configured, sessions can be set and fetched through the `sessions` helper:

```ruby
session[:foo] = 'bar'

puts session[:foo]
# => bar
```

Cookies can be set and fetched the same way:

```ruby
cookies[:foo] = 'bar'

puts cookies[:foo]
# => bar
```

By default, a cookie is created for path '/' and is set to expire in seven days. These defaults can be overridden by using the `Response#set_cookie` method:

```ruby
response.set_cookie :foo,
  value: 'bar',
  expires: Time.now + 3600,
  path: '/login'
  ```
