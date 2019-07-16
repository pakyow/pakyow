---
title: Navigating within the prototype
---

Prototypes are fully navigable through links and forms. To create a navigable element, hardcode a presentation path into the link `href` or form `action`.

Let's look at an example using the following frontend structure:

```
frontend/
  layouts/
    default.html
  pages/
    about.html
    index.html
    messages/
      index.html
      show.html
```

You can setup a link or form for navigating through your views using any of these presentation paths:

* `/`
* `/about`
* `/messages`
* `/messages/show`

Here's what a link would look like:

```html
<a href="/messages/show">
  View Message
</a>
```

And here's what a form would look like:

```html
<form action="/messages">
  <input type="submit" value="Submit">
</form>
```

When you click the link, you'll be navigated to the `frontend/pages/messages/show.html` page. Submitting the form will take you to the `frontend/pages/messages/index.html` page. This simulates a user creating a message and then being redirected back to their list of messages.
