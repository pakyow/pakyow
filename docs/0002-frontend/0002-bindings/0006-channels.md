---
title: Providing additional binding context
---

Sometimes it's necessary to have multiple bindings of the same type in a single view template. You might want to present two lists of posts—one presenting the latest messages, and the other presenting the most popular messages. Pakyow provides a feature called *binding channels* that lets you express additional intent behind your bindings.

Here's what a view template might look like for the case above:

```html
<section>
  <h1>
    Latest Messages:
  </h1>

  <article binding="message:latest">
    <p binding="content">
      latest message content
    </p>
  </article>
</section>

<section>
  <h1>
    Most Popular Messages:
  </h1>

  <article binding="message:popular">
    <p binding="content">
      popular message content
    </p>
  </article>
</section>
```

Channels are defined on the `binding` attribute in the format of:

```
{binding}:{channel}:{channel}
```

Pakyow will treat both lists as the `message` type, while addressing them separately for presentation. Here's how data would be exposed to each binding channel from the backend:

```ruby
expose "message:latest", [
  {
    content: "This is a recent message."
  }
]

expose "message:popular", [
  {
    content: "This is a popular message."
  }
]
```

And here's what the rendered view would look like:

```html
<section>
  <h1>
    Latest Messages:
  </h1>

  <article>
    <p>
      This is a recent message.
    </p>
  </article>
</section>

<section>
  <h1>
    Most Popular Messages:
  </h1>

  <article>
    <p>
      This is a popular message.
    </p>
  </article>
</section>
```


## Form binding channel

Pakyow automatically defines a binding channel for bindings defined on form elements. Forms serve a different intent in the user-interface, making it necessary to address them separately from other bindings.

To expose data to a form, data is exposed to the binding's `form` channel:

```ruby
expose "message:form", [...]
```
