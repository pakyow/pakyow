---
title: Specifying the layout for a page
---

In cases where you want to use a layout other than `default.html`, the page can specify the layout in its front-matter. For example, here's how to use a layout named `other.html` for a page:

<div class="filename">
  frontend/pages/index.html
</div>

```html
---
layout: other
---

...
```

* [Learn more about front-matter &rarr;](doc:frontend/front-matter)
