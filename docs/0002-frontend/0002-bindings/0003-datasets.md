---
title: Presenting datasets
---

Datasets consisting of more than one object can also presented with data bindings. Building on example from above, we expose three objects to be presented in the same view template as before:

```ruby
expose "message", [
  {
    content: "This is the first message."
  },
  {
    content: "This is the second message."
  },
  {
    content: "This is the third message."
  },
]
```

This is what the final rendered view will look like:

```html
<h1>
  Your Messages:
</h1>

<article>
  <p>
    This is the first message.
  </p>
</article>

<article>
  <p>
    This is the second message.
  </p>
</article>

<article>
  <p>
    This is the third message.
  </p>
</article>
```

Once again we see that presentation is simply the process of making the underlying view template match the data being presented.
