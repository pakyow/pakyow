---
title: Presenting nested data
---

Reflection will automatically include and present nested data when it can. For example, say you have a view template that presents messages along with replies for each message. Here's what the view template might look like:

<div class="filename">
  frontend/pages/index.html
</div>

```html
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

Reflection automatically creates a `replies` data source that's associated with the `messages` data source. The related endpoint will expose the messages that exist, along with any replies for each message. All of the data is presented together, resulting in a rendered view that looks something like this:

```html
<article>
  <p>
    message 1
  </p>

  <ul>
    <li binding="reply">
      <p binding="content">
        first reply to message 1
      </p>
    </li>
  </ul>
</article>

<article>
  <p>
    message 2
  </p>

  <ul>
    <li binding="reply">
      <p binding="content">
        first reply to message 2
      </p>
    </li>

    <li binding="reply">
      <p binding="content">
        second reply to message 2
      </p>
    </li>
  </ul>
</article>

<article>
  <p>
    message 3
  </p>

  <ul>
  </ul>
</article>
```

Notice that Message 3 doesn't have any replies. This is because no replies had been created for the message in the database. You can handle this use-case more elegantly using an `empty` version for the `reply` binding:

<div class="filename">
  frontend/pages/index.html
</div>

```html
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

    <li binding="reply" version="empty">
      no replies to this message yet
    </li>
  </ul>
</article>
```

Now the rendered view would look something like this:

```html
<article>
  <p>
    message 1
  </p>

  <ul>
    <li binding="reply">
      <p binding="content">
        first reply to message 1
      </p>
    </li>
  </ul>
</article>

<article>
  <p>
    message 2
  </p>

  <ul>
    <li binding="reply">
      <p binding="content">
        first reply to message 2
      </p>
    </li>

    <li binding="reply">
      <p binding="content">
        second reply to message 2
      </p>
    </li>
  </ul>
</article>

<article>
  <p>
    message 3
  </p>

  <ul>
    <li>
      no replies to this message yet
    </li>
  </ul>
</article>
```
