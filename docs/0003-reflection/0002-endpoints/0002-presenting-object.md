---
title: Presenting a specific object
---

Reflected endpoints will always expose a full dataset for presentation, except in cases where more context is available. For example, in the case of resource `show` endpoints, reflection reduces the dataset down to the specific object being shown.

Here's an example view template, defined at the `show` path for the message resource:

<div class="filename">
  frontend/pages/messages/show.html
</div>

```html
<article binding="message">
  <p binding="content">
    message content goes here
  </p>
</article>
```

Instead of exposing all the message data, the `show` endpoint for this view template will present a specific object. For example, if the request path was to `/messages/1`, reflection would present the message with an `id` of `1` in the database. If the object doesn't exist, the 404 (Not Found) page would be presented instead.

Reflection always chooses to present the specific object whenever additional context is available for the binding type. This is the case for `edit` endpoints, as well as endpoints for nested resources.
