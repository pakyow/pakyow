---
title: Inheritance
---

Front matter values defined in a layout are inherited by any page that uses the layout. For example, if the layout defines a page title like this:

```html
---
title: Layout Title
---
```

Every page will receive the same title. Pages can override the inherited value by simply redefining the title value in their own front matter:

```html
---
title: Page-Specific Title
---
```
