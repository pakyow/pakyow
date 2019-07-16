---
title: Specifying the action endpoint
---

You can always specify the action endpoint for a form. This is useful in cases where you need to break away from the default conventions, and required in cases like delete actions (we'll discuss delete actions more in the next section).

To define an action endpoint, just set the `endpoint` attribute on the element:

```html
<form binding="message" endpoint="messages_create">
  ...
</form>
```

You can see information about defined actions, including their names, by running the `info:endpoints` command from the command line.

## Custom actions

If your backend defines a custom action not handled by reflection, you can hook the form up to it by setting the `endpoint` attribute as discussed above. For example, say there's an endpoint for messages named `increment` that increments an internal counter of some sort. We can hook up a form to the `increment` endpoint like this:

```html
<article binding="message">
  <p binding="content">
    message content goes here
  </p>

  <form endpoint="messages_increment">
    <input type="submit" value="Give a thumbs up">
  </form>
</article>
```

When submitted, the form will call the custom `increment` action on the backend.
