---
name: View Transformation Protocol
desc: Learn about the view transformation protocol.
---

The View Transformation Protocol is a way to represent view rendering as a set
of instructions that can later be applied to the view template. Pakyow
implements this protocol on the backend for initial rendering and in [Ring](https://github.com/pakyow/ring) for
client-side rendering.

Let's look at an example. Here's the view template:

```html
<div data-scope="post">
  <p data-prop="content">
    content here
  </p>
</div>
```

Here's some example rendering code:

```ruby
data = []
data << { id: 1, content: 'one' }
data << { id: 2, content: 'two' }
data << { id: 3, content: 'three' }

view.scope(:post).apply(data)
```

The necessary view transformations can be represented by this bit of JSON:

```json
[
  [
    "apply",
    [
      {
        "id": 1,
        "content": "one"
      },

      {
        "id": 2,
        "content": "two"
      },

      {
        "id": 3,
        "content": "three"
      },
    ], []
  ]
]
```

Once these transformations are applied to the template, the view accurately
presents the new state:

```html
<div data-scope="post" data-id="1">
  <p data-prop="content">
    one
  </p>
</div>

<div data-scope="post" data-id="2">
  <p data-prop="content">
    two
  </p>
</div>

<div data-scope="post" data-id="3">
  <p data-prop="content">
    three
  </p>
</div>
```

Notice that the underlying knowledge of state is preserved in the rendered view.
This allows for future rendering instructions to be applied to the view without
starting with the original template each time.

The View Transformation Protocol implements the full View API as described here:

- http://pakyow.org/docs/view-logic/api
