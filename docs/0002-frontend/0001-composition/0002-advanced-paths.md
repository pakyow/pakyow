---
title: Advanced presentation paths
---

Presentation at nested paths are also supported. Looking at the previous example, requests to http://your-site.com/messages/show would match the `frontend/pages/messages/show.html` page. This page would be composed into the layout and then rendered as before.

In reality, the request path for a page like this will be based on the message that was to be presented. For example, the full url look like this:

* http://your-site.com/messages/1

In cases like this it's typical for same underlying template to be rendered for multiple requests, with only the data changing between requests. We'll cover this type of dynamic presentation in the next guide on data bindings.
