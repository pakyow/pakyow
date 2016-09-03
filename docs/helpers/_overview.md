---
name: Helpers
desc: Pakyow helper methods.
---

Helper methods are defined in the Pakyow::Helpers module. You can define your own helpers in `app/lib/helpers.rb`:

```ruby
module Pakyow::Helpers
  def do_something
    # ...
  end
end
```

The helpers are automatically included into routes and bindings. You can add them to any class by including:

```ruby
include Pakyow::Helpers
```
