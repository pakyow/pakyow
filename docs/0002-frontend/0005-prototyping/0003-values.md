---
title: Prototyped values
---

Values defined in binding nodes are considered to be prototype values. They are replaced when data is presented during rendering, but they remain visible when running in prototype mode. This lets you design your interface using realistic values without needing to go back and remove them later.

Here's an example view template that will present a message:

```html
<article binding="message">
  <p binding="content">
    message content goes here
  </p>
</article>
```

In prototype mode, you'll see the "message content goes here" text. When presented with real data, the "message content goes here" value will be replaced with the actual content of the message.
