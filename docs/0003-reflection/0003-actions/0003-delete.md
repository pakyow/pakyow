---
title: Setting up delete actions
---

Delete actions usually aren't tied to forms. Instead, delete actions are usually triggered by links or buttons. Here's an example view template that defines a delete link for a message:

```html
<article binding="message">
  <p binding="content">
    message content goes here
  </p>

  <a endpoint="messages_delete">
    Delete this message
  </a>
</article>
```

Setting up a delete action requires the endpoint to be defined explicitly on the link. Reflection understands your intent based on the name of the endpoint, setting up the delete action for you on the backend. When the link is clicked, the delete endpoint will be invoked and the data deleted.

Pakyow does a few other things to create a nice user experience for delete endpoints. This is discussed more in the frontend docs, so check that out if you want to learn more.

* [Read more about delete in the frontend &rarr;](doc:frontend/endpoints/delete)
