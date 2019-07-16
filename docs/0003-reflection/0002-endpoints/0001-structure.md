---
title: Building a resource-based view structure
---

Reflection makes some decisions about how to structure backend endpoints based on the structure found in your view templates. One of the conventions it relies on is REST, or [Representational State Transfer](https://en.wikipedia.org/wiki/Representational_state_transfer).

REST defines conventions for http apis based around resources. In Reflection, a RESTful resource is defined when an endpoint will interact directly with a data source. Consider the following view template:

<div class="filename">
  frontend/pages/messages/index.html
</div>

```html
<article binding="message">
  <p binding="content">
    message content goes here
  </p>
</article>
```

If you recall from the previous guide, Pakyow defines a `messages` data source that matches the `message` binding from the view template. Because the view template is defined within the resource path (`messages/index.html`), Reflection defines the endpoint for this view within a `messages` resource.

Resources are just controllers that implement a RESTful api. The `messages/index.html` page is tied to the `list` endpoint in the `messages` resource. This endpoint is responsible for listing all of the messages contained by a resource. In practical terms this means that all the messages in the database will be presented by the `messages/index.html` view.

REST defines several other endpoints that reflection makes use of. Here's a list, along with what view templates the endpoint is mapped to:

* `list`: This endpoint is responsible for presenting a list of objects for a resource. The request path is structured as `GET /messages`. Reflection maps view templates like `messages/index.html` to this endpoint.
* `show`: This endpoint is responsible for presenting a specific object within a resource. The request path is structured as `GET /messages/:id`, where `:id` is the unique id tied to the object in the database. Reflection maps view templates like `messages/show.html` to this endpoint.
* `new`: This endpoint is responsible for presenting the form for a new object. The request path is structured as `GET /messages/new`. Reflection maps view templates like `messages/new.html` to this endpoints.
* `edit`: This endpoint is responsible for presenting the form for a specific object within a resource. The request path is structured as `GET /messages/:id/edit`, where `:id` is the unique id tied to the object in the database. Reflection maps view templates like `messages/edit.html` to this endpoint.

## Nested resources

REST allows for nested resources in cases where one resource is related to another. Reflection uses this to handle associations between data sources. For example, if you wanted to present a list of replies for a specific message, you would define a view template like this:

<div class="filename">
  frontend/pages/messages/replies/index.html
</div>

```html
<h1>
  Replies to your message:
</h1>

<article binding="reply">
  <p binding="content">
    reply content goes here
  </p>
</article>
```

Reflection renders this view with a list of replies for a specific message. The request path would be structured as `GET /messages/:message_id/replies`, where `:message_id` is the id of the specific object in the database.

Nested resources can also contain endpoints for `show`, `new`, and `edit` just like top level resources.
