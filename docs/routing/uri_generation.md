---
name: URI Generation
desc: Building URIs from route definitions.
---

Pakyow provides a way to generate full URI strings from a named route and route data. This means the URI is defined once (in the route definition) and can be used throughout the application without duplication. API changes are much less menacing.

Let's start with a simple route:

```ruby
get :foo, 'foo' do
  # ...
end
```

The URI for the `:foo` route can be generated from the current instance of `Router`:

```ruby
router.path :foo
# => /foo
```

For routes with arguments, data can be passed to `#path` that is applied to the generated URI:

```ruby
get :bar, 'bar/:my_arg' do; end
router.path :bar, my_arg: '123'
# => /bar/123
```

Any object can be passed as data to `#path` that supports key lookup (e.g. `Hash`).

## Grouped Routes

To generate a URI for a grouped route, simply look up the group before calling `#path`:

```ruby
group :foo do
  get(:bar, 'bar') do; end
end
router.group(:foo).path :bar
# => /bar
```

Routes in nested groups are referenceable by the group they directly belong to.
