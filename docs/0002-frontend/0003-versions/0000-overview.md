---
title: View Versions
---

It's often necessary to present data in different ways. For example, when presenting a list of messages you may want to distinguish between "read" and "unread" messages, adding a specific class to "unread" messages to make them more visible to the user. Pakyow lets you do this with versions.

Multiple versions of a template can be defined for any binding. The example from above could be defined like this:

```html
<article binding="message">
  <h1 binding="title">
    message title goes here
  </h1>
</article>

<article class="unread" binding="message" version="unread">
  <h1 binding="title">
    message title goes here
  </h1>
</article>
```

The `unread` version has a class of the same name, allowing it to be styled differently from read messages. When presenting data, the first `message` binding will be rendered unless the `unread` version is used explicitly.

Versions live alongside data bindings to make up another aspect of the presentation contract between the frontend and backend. The frontend defines the available versions and the backend make a decision to use one version or another based on some condition of the presented data.
