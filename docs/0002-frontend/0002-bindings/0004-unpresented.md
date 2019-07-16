---
title: Removing un-presented bindings
---

If data isn't exposed for a binding, it will be removed during rendering. This works at both the level of a binding type as well as individual attributes. For example, say we expose a message object that doesn't have an attribute:

```ruby
expose "message", {
}
```

The rendered view would look like this:

```html
<h1>
  Your Messages:
</h1>

<article>
</article>
```

If a message isn't exposed at all, the rendered view would look like this:

```html
<h1>
  Messages
</h1>
```

Cleaning up un-presented bindings ensures that prototype values are never presented in the final rendered view.
