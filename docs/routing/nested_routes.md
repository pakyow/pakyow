---
name: Nested Routes
desc: Nesting groups, namespaces, and template expansions.
---

Groups, namespaces, and template expansions can each be nested at multiple levels. Nesting makes it easier to create and maintain complex route sets, like so:

```ruby
namespace :foo, 'foo' do
  default do
    # ...
  end

  namespace :bar, 'bar' do
    default do
      # ...
    end
  end
end
```

Two routes are created:

  - GET /foo
  - GET /foo/bar

Adding a group to a namespace is just as easy:

```ruby
namespace :foo, 'foo' do
  default do
    # ...
  end

  namespace :bar, 'bar' do
    default do
      # ...
    end
  end

  group before: [:protect] do
    get '/cannot_see_this' do
      # ...
    end
  end
end
```

In this case four routes are created:

  - GET /foo
  - GET /foo/bar
  - GET /foo/cannot_see_this

The grouped route inherits the `protect` hook from the group it belongs in. So as expected, hooks are applied at and below the depth they are defined.
