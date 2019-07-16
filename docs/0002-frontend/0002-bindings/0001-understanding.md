---
title: How Pakyow understands bindings
---

> [callout] This section contains a bit of backend Ruby code, but don't worry if it doesn't make sense! It's only there to help get a full understanding of how data bindings work across the stack.

Bindings extend the natural hierarchy of HTML to define a data structure within the template. Using the example from above, if you remove nodes that don't represent data bindings this simple data structure emerges:

```
message:
  - content
```

This structure is exactly what Pakyow. When Pakyow renders the view, it looks for data exposed on the backend that matches the data structure represented by the view, then populates the view with the data.

For example, a single message can be exposed like this:

```ruby
expose "message", {
  content: "This is our first message!"
}
```

Pakyow presents the data in the template, resulting in this rendered view:

```html
<h1>
  Your Messages:
</h1>

<article>
  <p>
    This is our first message!
  </p>
</article>
```

In a nutshell, that's all there is to view rendering in Pakyow! We can summarize the steps for view rendering like this:

1. The view template declares its intent using the natural hierarchy found in HTML, along with sprinkles of data binding attributes.

2. The backend gathers and exposes data for a presentation intent ahead of view rendering.

3. Pakyow connects the frontend and backend together by matching their intents. The result is a fully rendered view that presents dynamic data.

The frontend and backend never talk directly to each other, even when it comes to presenting dynamic data. Instead, the frontend view templates define a presentation contract based on what it wants to present.

This approach gives the frontend designer full control over presentation without introducing any complex rendering logic to the view templates. It also benefits the backend developer by not involving them with all of the various presentation concerns. Each role is able to stay focused on their core concerns while communicating effectively through the common presentation contract.
