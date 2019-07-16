---
title: Form endpoints
---

You can set endpoints on forms as well. Pakyow will automatically setup a form with the correct `action` and `method` for submitting the form to the endpoint you define.

For example, say we have the following endpoints:

```
:messages_create          POST  /messages
:messages_replies_create  POST  /messages/:message_id/replies
:messages_show            GET   /messages/:id
:root                     GET   /
```

You can connect the form to the `messages_create` endpoints like this:

```html
<form endpoint="messages_create">
  ...
</form>
```

The rendered version of the form will look like this:

```html
<form action="/messages" method="post">
  ...
</form>
```

Defining an endpoint is usually better than hardcoding an `action` and `method` yourself, since the form will automatically adjust to handle any changes to the backend endpoints. The endpoint path or http method could be changed, but as long as the name of the endpoint is the same the form will continue to work.

* [Learn more about forms &rarr;](doc:frontend/forms)
