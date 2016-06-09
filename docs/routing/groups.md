---
name: Grouping Routes
desc: Grouping similar routes.
---

Groups make it possible to organize related routes. A route group can be named and used later when [looking up and creating a route URI](/docs/routing/uri-generation). Names are optional, but routes in an unnamed group cannot be accessed for URI generation.

```ruby
group :foo do
  get '/bar' do
    # ...
  end
end
```

[Hooks](/docs/routing/hooks) can be applied to a group of routes, making it easier to organize back-end logic. A common need in a web-based application is to protect parts of the application so that only authenticated users have access. Though an easy problem to solve conceptually, it becomes tedius to define and manage the routes if hooks are applied to each route individually. Instead, we can use route groups:

```ruby
fn :require_auth do
  redirect '/' unless session[:user]
end

group :protected, before: [:require_auth] do
  get '/foo' do
    p 'you found foo'
  end

  get '/bar' do
    p 'you found bar'
  end
end

group :unprotected do
  default do
    p 'this route is unprotected'
  end
end
```

Looking at the code above we have a much better understanding of what the routes do. It's also easier to add or reorganize routes in the future.
