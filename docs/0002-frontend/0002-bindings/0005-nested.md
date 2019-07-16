---
title: Presenting nested objects
---

Binding types can contain other types, giving you a way to present data that contains related data. Let's build on our message example from above to add the concept of replies to the view template:

```html
<h1>
  Your Messages:
</h1>

<article binding="message">
  <p binding="content">
    message content goes here
  </p>

  <ul>
    <li binding="reply">
      <p binding="content">
        reply content goes here
      </p>
    </li>
  </ul>
</article>
```

Here we again rely on the hierarchical nature of HTML to represent our view in a way that not only makes sense from a frontend design perspective, but opens the door to presenting complex data.

Let's expose a single message with many replies for rendering:

```ruby
expose "message", {
  content: "This is our first message!",

  replies: [
    {
      content: "Reply 1"
    },
    {
      content: "Reply 2"
    },
    {
      content: "Reply 3"
    }
  ]
}
```

Here's what the rendered view would look like:

```html
<h1>
  Your Messages:
</h1>

<article>
  <p>
    This is our first message!
  </p>

  <ul>
    <li>
      <p>
        Reply 1
      </p>
    </li>

    <li>
      <p>
        Reply 2
      </p>
    </li>

    <li>
      <p>
        Reply 3
      </p>
    </li>
  </ul>
</article>
```

Pakyow has a basic understanding of language rules, allowing it to match the `replies` data to the `reply` binding in the view template. The result is a rendered view that exactly matches the exposed data.
