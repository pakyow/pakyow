---
title: Using nested forms
---

Reflection gracefully handles forms nested within bindings. Let's walk through a couple of examples that illustrate how you can use nested forms to build more complex behavior into your interface.

## Forms for the parent binding

The first use-case for nested forms is defining a form specifically for the parent binding that contains it. You could use this approach to define an edit form for every message in a list. Here's what a view template might look like in this case:

```html
<article binding="message">
  <p binding="content">
    message content goes here
  </p>

  <form endpoint="messages_update">
    <div class="form-field">
      <label for="content">
        Update this message:
      </label>

      <input type="text" binding="content">
    </div>

    <input type="submit" value="Save">
  </form>
</article>
```

When Reflection presents the messages, it sets up each form for updating the message that the form is presented for. Submitting the form for a message will update the related message with a new `content` value.

## Forms for a new binding type

Nested forms are also useful for creating related data for a parent binding. For example, we might want to let users reply to messages. This can be done by defining a form for a new binding type within the parent binding:

```html
<article binding="message">
  <p binding="content">
    message content goes here
  </p>

  <form endpoint="reply">
    <div class="form-field">
      <input type="text" placeholder="Leave a reply..." binding="content">
    </div>

    <input type="submit" value="Submit">
  </form>
</article>
```

When Reflection presents the message, it sets up the reply form for creating new replies. Replies created through the form will also be associated with the message they were created for. This behavior relies on the [reflected association behavior for data sources](doc:reflection/data-sources).
