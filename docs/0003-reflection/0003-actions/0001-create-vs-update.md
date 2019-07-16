---
title: Forms for create vs update
---

Reflection defines either a `create` or `update` action for forms it finds in your view templates. One of these two actions is chosen based on the form's context. We'll go through all the conventions around form actions in this section.

## Forms for create

All forms are connected to a `create` action unless additional context is available. This includes forms defined at the RESTful presentation path for `new`, as well as standalone forms that aren't connected to any outside context.

For example, this form will be connected to a `create` action for `messages`:

<div class="filename">
  frontend/pages/messages/new.html
</div>

```html
<form binding="message">
  ...
</form>
```

This form will also be connected to the same action:

<div class="filename">
  frontend/pages/index.html
</div>

```html
<form binding="message">
  ...
</form>
```

And finally, forms for a nested binding type will also be connected to a `create` action:

<div class="filename">
  frontend/pages/index.html
</div>

```html
<article binding="message">
  <form binding="reply">
    ...
  </form>
</article>
```

Reflection defines a `create` action for `comments` as a child resource to `messages`. This means that comments created through the above form will automatically be associated with the message they are defined within.

* [Read more about nested forms &rarr;](doc:reflection/actions/nested-forms)

## Forms for update

Reflection defines an `update` action when a form is defined at a presentation path matching the RESTful edit path for a resource. For example, this view template will be connected to an `update` action for `messages`:

<div class="filename">
  frontend/pages/messages/edit.html
</div>

```html
<form binding="message">
  ...
</form>
```

Reflection makes this connection because 1) the form is defined in a view template at a presentation path for edit and 2) the form is setup for the resource we're editing. This tells reflection that your intent is to edit a message, then update it in the database.

You must set an endpoint explicitly to connect other forms to `update`. Reflection will use the context from the current request path to build the correct action. For example, this form, defined at the presentation path for showing a message, would be connected to an `update` action for the message being shown:

<div class="filename">
  frontend/pages/messages/show.html
</div>

```html
<form binding="message" endpoint="messages_update">
  ...
</form>
```

This also works in the case of forms nested within the binding type they are for:

<div class="filename">
  frontend/pages/messages/index.html
</div>

```html
<article binding="message">
  <form endpoint="messages_update">
    ...
  </form>
</article>
```

Reflection will render the `message` binding once for every message, settting up an update form for each one. Form endpoints are discussed more in the next section.
