---
title: Adding the replies feature
---

Users need a way to reply to messages that have already been created. We'll add this new feature to by following the same design-first process as before. Start by hitting `Ctrl-C` and booting back into the prototype:

```
pakyow prototype
```

Let's start by defining another page template that presents a message along with its replies. Create this template in a new `frontend/pages/messages` folder. This tells Pakyow what requests should use the new template and helps keep your frontend organized. Here's the html for the new show template:

<div class="filename">
  frontend/pages/messages/show.html
</div>

```html
<article binding="message">
  <p binding="content">
    Message content goes here.
  </p>

  <hr>

  <article binding="reply">
    <p binding="content">
      Reply content goes here.
    </p>
  </article>

  <p binding="reply" version="empty">
    No replies yet.
  </p>

  <hr>

  <form binding="reply" ui="form">
    <ul class="form-errors" ui="form-errors">
      <li binding="error.message">
        Error message goes here.
      </li>
    </ul>

    <div class="form-field">
      <input type="text" binding="content" placeholder="Leave a reply..." required>
    </div>

    <input type="submit" value="Reply">
  </form>
</article>
```

Navigate to http://localhost:3000/messages/show in your web browser to see the new page. Just like before, you'll see everything just as you defined it:

![Pakyow Example: Message Show Prototype](https://github.com/metabahn/pakyow-marketing-public/raw/master/docs/common/images/hello-example-screen-8.png "Pakyow Example: Message Show Prototype")

Next, let's setup some links to give users a way to navigate between pages. Start by adding the following link to the top of the show message page:

<div class="filename">
  frontend/pages/messages/show.html
</div>

```html
<a href="/">
  Go back home
</a>

<article binding="message">
  ...
</article>
```

Users also need a way to view messages. Do this in the index page by adding the following add a link to the message element:

<div class="filename">
  frontend/pages/index.html
</div>

```html
...

<article binding="message">
  <p binding="content">
    Message content goes here.
  </p>

  <a href="/messages/show" endpoint="messages_show">
    View message
  </a>
</article>

...
```

Reload your web browser and you'll be able to navigate between pages in your prototype!

Okay, this feature seems pretty solid, so let's see it in action.

Hit `Ctrl-C` and boot back into normal development mode:

```
pakyow boot
```

Reload your web browser and play around with the app for a bit. You'll be able to create messages, click on the link to view them, and then add replies. Pakyow has hooked everything up for you and attached behavior to your interface. The app offers a nice user-experience out of the box, with both pages updating to show new messages and replies as they're created.
