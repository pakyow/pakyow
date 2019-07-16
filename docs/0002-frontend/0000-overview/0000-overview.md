---
title: Frontend
---

Pakyow separates your application into two primary concerns:

1. Frontend: HTML View Templates and Assets (images, stylesheets, scripts) that define what users see in their web browser.

2. Backend: Ruby code that runs on the backend web server, handling things like routing, database interactions, and rendering.

We'll discuss everything about the frontend in this series of guides, while backend concerns will be covered separately later on.

Each concern has its own folder at the top level of the application, aptly named `frontend` and `backend`. You can work on either side of the application in complete isolation from the other side. This means that when you're working on the frontend everything you'll need is right at your fingertips within the `frontend` directory.

Separation is maintained at every level of the application stack. Everything describing how the frontend works is defined in the frontend folder, usually within the view templates themselves.

Let's look at a frontend view template you might see in a typical project:

```html
<article binding="message">
  <p binding="content">
    message content goes here
  </p>
</article>
```

In the above example, the `binding` attribute defines the data that the view template wants to present. When Pakyow renders this template, any data exposed for the `message` binding will automatically be presented by this part of the view template.

Neither the frontend or the backend explicitly defines how a view template will to be presented. Instead, the frontend describes the semantic intent of the interface, while the backend exposes data for a particular intent. Pakyow is responsible for connecting the two concerns together through the common language of semantic intent.
