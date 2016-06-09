---
name: Route Mixins
desc: Reusing routes with mixins.
---

Once you outgrow a single route set it becomes necessary to share routes and functions between sets. This can be accomplished with route mixins.

Here's a mixin definition:

```ruby
module SharedRoutes
  include Pakyow::Routes

  fn :bar
  end
end
```

This mixin can now be included into any set, making the `bar` route function available:

```ruby
Pakyow::App.routes :my_route_set do
  include SharedRoutes

  get 'foo', before: [:bar] do
  end
end
```
