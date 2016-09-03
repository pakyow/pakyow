---
name: Namespacing Routes
desc: Namespacing similar routes.
---

Namespaces make it possible to group routes under a common URI.

```ruby
namespace 'foo' do
  default do
    p 'foo: default'
  end

  get 'bar' do
    p 'foo: bar'
  end
end

# sending a GET request to '/foo' prints 'foo: default'
# sending a GET request to '/foo/bar' prints 'foo: bar'
#
# sending a GET request to '/' or '/bar' results in a 404
```

A namespace is implemented as a special kind of [group](/docs/routing/groups), so everything about a group is also true of a namespace. This means that namespaces can be assigned hooks and given a name.

```ruby
namespace :foo, 'foo', before: [:some_hook] do
  # foo routes go here
end
```
