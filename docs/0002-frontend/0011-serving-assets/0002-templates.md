---
title: Referencing assets in a view template
---

You can use assets in your view templates just as you would normally:

```html
<img src="/images/logo.png">
```

Note that the `/assets` prefix is left off from asset references in the view template. This keeps you from having to update asset references if you decide to serve assets from a different endpoint. Pakyow automatically updates asset references to the final paths when it renders the view. You'll see more of this behavior later when we talk about fingerprinting assets in production.
