---
title: Handling empty views
---

One of the more common patterns is handling what a view looks like when no data is available. It's helpful to reassure users that nothing is broken and nudge them towards what action they should take next.

Pakyow provides a pattern for empty views right out of the box. Setting up a view in a default empty state is as easy as defining `empty` versions for the binding. Here's an example:

```html
<article binding="message">
  <h1 binding="title">
    message title goes here
  </h1>
</article>

<article binding="message" version="empty">
  <p>
    Couldn't find any messages. Try creating one!
  </p>
</article>
```

Pakyow will automatically use the empty version when there's no data to present for the binding, without any further direction from the backend.
