---
title: Setting page titles
---

Right now both pages in our project use the page title specified in the layout. Let's set a custom page title on the message show page to differentiate it. We'll add some configuration, called front-matter, to the top of the page template:

<div class="filename">
  frontend/pages/messages/show.html
</div>

```html
---
title: "View Message"
---

...
```

Reload the page and you'll see that the new page title is used for the message page. Dynamic values are also supported. For example, you can present the message content in the title like this:

```html
---
title: "{message.content} | View Message"
---

...
```
