---
title: Using delete endpoints
---

Delete endpoints are a bit different than standard navigation endpoints as they cause a destructive action to occur. However, Pakyow still handles delete endpoints in a similar way to other endpoints.

To create a link that triggers a delete endpoint just specify the name of the endpoint like you would for other endpoints:

```html
<h1>
  Here's a list of your messages:
</h1>

<article binding="message">
  <h1 binding="title">
    message title goes here
  </h1>

  <a href="/messages/show" endpoint="messages_delete">
    Delete Message
  </a>
</article>
```

In normal cases, clicking a link causes the browser send a `GET` request to the server. Here Pakyow works some magic to turn delete links into a form that triggers the `DELETE` endpoint when submitted.

Since delete endpoints are turned into forms, the endpoint element should be capable of submitting a form when clicked. There are two approaches to choose from. The first approach is to use a submit button:

```html
<input type="submit" value="Delete Message" endpoint="messages_delete">
```

If this doesn't work, the second approach is to attach the `submittable` component to the endpoint element:

```html
<a href="/messages/show" endpoint="messages_delete" ui="submittable">
  Delete Message
</a>
```

The `submittable` component will automatically submit its parent form when clicked.


## Confirming the delete action

Pakyow.js ships with a `confirmable` component that can be useful for destructive endpoints like delete. The component presents a confirmation dialog they must accept after invoking the delete endpoint. Without the confirmation, the endpoint will not be triggered.

To use the `confirmable` component, simply add it to the element:

```html
<article binding="message">
  <a href="/messages/show" endpoint="messages_delete" ui="confirmable">
    Delete Message
  </a>
</article>
```
