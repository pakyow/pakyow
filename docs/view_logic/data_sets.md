---
name: Working With Data Sets
desc: Binding a data set to a view.
---

We've seen how Pakyow can bind a single piece of data, but it can also handle
data sets. Let's look at an example where two blog posts are bound to our view:

```ruby
data = [
  {
    title: 'First Post',
    body:  'This is the first post'
  },

  {
    title: 'Second Post',
    body:  'This is the second post'
  },
]

view.scope(:post).apply(data)
```

Notice that the view logic for binding both a single piece of data and a data
set are identical. This is possible because binding is data-driven, keeping us
from describing how the data should be applied to the view and instead saying
only that it should be applied.

Here's the result:

```html
<div data-scope="post">
  <h1 data-prop="title">
    First Post
  </h1>

  <p data-prop="body">
    This is the first post
  </p>
</div>

<div data-scope="post">
  <h1 data-prop="title">
    Second Post
  </h1>

  <p data-prop="body">
    This is the second post
  </p>
</div>
```

Pakyow applies data in two steps. First, the structure of the view is
transformed to match the structure of the data being applied. In the case above,
the resulting view contains two post scopes because our data consists of two
posts. Once the view and data match, binding the data is as simple as connecting
the dots.
