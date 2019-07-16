---
title: Ordering the dataset
---

You may notice that messages are displayed oldest at the top. This doesn't make a whole lot of sense with the form being at the top, so let's change this. Add the following `dataset` attribute to the message binding on the index page:

<div class="filename">
  frontend/pages/index.html
</div>

```html
<article binding="message" dataset="order: created_at(desc)">
  ...
</article>

...
```

Reload the page and the messages will be presented with the newest at the top:

![Pakyow Example: Ordered Message List](https://github.com/metabahn/pakyow-marketing-public/raw/master/docs/common/images/hello-example-screen-9.png "Pakyow Example: Ordered Message List")

You've just used a built-in Pakyow tool called Reflection, one feature of which lets you configure certain aspects of the presented dataset right in the view where it's used. In addition to the order, you can also set a limit to the amount of data presented, as well as specify the underlying query to use for fetching data. More on Reflection in a moment.
