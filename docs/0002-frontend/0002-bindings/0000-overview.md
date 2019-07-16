---
title: Data Bindings
---

Pakyow view templates can present dynamic data, but don't contain any presentation logic themselves. Instead, they declare their semantic intent through a few special attributes that describe the dynamic data that the template wants to present.

Let's look at an example:

```html
<h1>
  Your Messages:
</h1>

<article binding="message">
  <p binding="content">
    message content goes here
  </p>
</article>
```

The `binding` attribute declares the intent to present dynamic data on the node, while also defining what specific type or attribute to present. In this example, the `article` represents a `message` type, with `content` being the sole attribute of the `message` type.
