---
title: Using parts of bound values
---

So far we've only seen examples of presenting content in binding nodes. However, one or more attributes can also be added to a binding node during presentation. The frontend designer can control how presentation affects a particular binding node by including or excluding specific parts.

To be sure that the binding node is only changed in a specific way, use the `include` attribute like this:

```html
<article binding="message">
  <p binding="content" include="content class">
    message content goes here
  </p>
</article>
```

Now only the values for `content` and `class` will be presented on the node (`content` referring to the text content within the node). You can also use the `exclude` attribute to exclude specific parts:

```html
<article binding="message">
  <p binding="content" exclude="class">
    message content goes here
  </p>
</article>
```

Now the `title` node will never present a value for `class`.
