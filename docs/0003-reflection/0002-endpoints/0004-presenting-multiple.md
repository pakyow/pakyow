---
title: Presenting to multiple bindings of a single type
---

Sometimes you might want to present the same type of data twice on the same page. For example, maybe you want to present two lists of messages: one for the most recent posts and another ordered alphabetically. Pakyow gives you a way to accomplish this with a feature called binding channels.

Here's what the view template might look like for a use-case like this:

```html
<h1>
  Most recent messages:
</h1>

<article binding="message:recent">
  <p binding="content">
    message content goes here
  </p>
</article>

<h1>
  Messages in alphabetical order:
</h1>

<article binding="message:alphabetical">
  <p binding="content">
    message content goes here
  </p>
</article>
```

Each `message` binding is defined with a channel, respectively named `recent` and `alphabetical`. In the next section we'll learn how to present different datasets for each of these bindings.

* [Read more about binding channels &rarr;](doc:frontend/bindings/channels)
