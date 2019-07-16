---
title: Composing assets for view templates
---

Stylesheets and Scripts can be added to the frontend folder and composed together just like layouts, pages, and partials. Let's revisit the example from above and add in a few assets to illustrate how asset composition works:

```
frontend/
  layouts/
    default.html
    default.css
  pages/
    index.html
    messages/
      show.html
      show.js
```

Here we define two stylesheets, along with a single `messages/show.js` script. The `default.css` stylesheet will automatically be included into any page that uses the `default` layout. The `show.js` script will be included into the the `messages/show.html` page when rendered.

Composed assets are automatically included as an asset pack in the `<head>` section of the composed view.

* [Learn more about asset packs &rarr;](doc:frontend/asset-packs)
