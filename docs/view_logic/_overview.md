---
name: View Logic
desc: Rendering data in views.
---

Pakyow views are logicless and data is instead bound into the view from the
application logic. This is possible by making the view aware of the data it presents.

A data-aware view contains nodes labeled as a scope (`data-scope`) or a prop
(`data-prop`). A scope defines a type of data and usually wraps one or more props.
For example, a view that is responsible for presenting a blog post might have a
scope called `post` that wraps props `title` and `body`:

```html
<div data-scope="post">
  <h1 data-prop="title">
    Title Goes Here
  </h1>

  <p data-prop="body">
    Body goes here.
  </p>
</div>
```

When binding data to a view, only the nodes that represent a scope or prop, or
the significant nodes, are important. All insignificant nodes are ignored.

Binding data to our view is as simple as finding the entry point (the scope) and
mapping the attributes across the nodes. This is done with the `bind` method,
like this:

```ruby
data = {
  title: 'First Post',
  body:  'This is the first post'
}

view.scope(:post).bind(data)
```

For this example our data is represented as a Hash. However, Pakyow can bind any
object that responds to a hash-like lookup (e.g. `my_object[:my_attribute]`).
Most Ruby ORMs such as Sequel, Ruby Object Mapper, and ActiveRecord support this
style of lookup.

Here's the resulting view:

```html
<div data-scope="post">
  <h1 data-prop="title">
    First Post
  </h1>

  <p data-prop="body">
    This is the first post
  </p>
</div>
```

The binding process is driven by the view. Pakyow inspects the data for a
matching value for each prop. If no match is found, an "unbound data" warning is
issued.
