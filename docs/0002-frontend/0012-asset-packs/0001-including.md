---
title: Including packs
---

To include a pack in a view template, add it to template's front-matter:

<div class="filename">
  frontend/pages/index.html
</div>

```html
---
packs:
- example
---

<p>
  This content will be styled red.
</p>
```

Pakyow will load the pack's styles into the stylesheet for the view, adding the red color to the paragraph tag. Packs can be included into any view template, including layouts and partials. The pack will be loaded anytime the view template is used during rendering.

Packs can define styles, scripts, or both. Let's add some JavaScript to the `example` pack:

<div class="filename">
  frontend/assets/packs/example.js
</div>

```javascript
console.log("hello from the example pack");
```

The paragraph text will still receive the red styling, but now the "hello from the example pack" message will appear in the browser's console, showing that the JavaScript was successfully loaded and executed.

## Inheriting included packs

Packs included by a layout are inherited by all pages that use the layout. For example, this layout template includes a single pack named `example`:

<div class="filename">
  frontend/layouts/default.html
</div>

```html
---
packs:
- example
---

<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
</head>

<body>
  <!-- @container -->
</body>
</html>
```

Here's a page template that includes an additional pack named `page-pack`:

<div class="filename">
  frontend/pages/index.html
</div>

```html
---
packs:
- page-pack
---

...
```

Since the page uses the `default` layout, both packs will be included into the composed view.
