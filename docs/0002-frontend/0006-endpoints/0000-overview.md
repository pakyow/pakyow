---
title: Endpoints
---

Endpoints let you define how a user will navigate through your application. They also provide helpers for determining whether a particular navigation element is in a current or active state.

Let's look at an example. Our application has two endpoints: one for viewing a list of messages and another for showing the details of a particular message. We can setup navigations between these two views using the `endpoint` attribute on the node:

Consider an app with two views: one for viewing a list of messages and one with more details for a single message. You can use endpoints to setup navigations between the two views. Let's start by setting up a link that lets a user navigate from the message list to the show view:

```html
<h1>
  Here's a list of your messages:
</h1>

<article binding="message">
  <h1 binding="title">
    message title goes here
  </h1>

  <a href="/messages/show" endpoint="messages_show">
    View Message
  </a>
</article>
```

The `messages_show` endpoint value references a named endpoint within the application. When the view is rendered, Pakyow replaces the defined `href` with the path defined by the `messages_show` endpoint. Given a list of three messages, the rendered view will look something like this:

```html
<h1>
  Here's a list of your messages:
</h1>

<article>
  <h1>
    Message 1
  </h1>

  <a href="/messages/1">
    View Message
  </a>
</article>

<article>
  <h1>
    Message 2
  </h1>

  <a href="/messages/2">
    View Message
  </a>
</article>

<article>
  <h1>
    Message 3
  </h1>

  <a href="/messages/3">
    View Message
  </a>
</article>
```

The endpoints are built based on the presented data, populating each link with a unique href. Clicking on the link for a message will direct you to the endpoint that represents `messages_show`—whatever that might be. As the frontend designer, you aren't required to know the particulars. Instead, you simply define the behavior you want and the connections are made for you.
