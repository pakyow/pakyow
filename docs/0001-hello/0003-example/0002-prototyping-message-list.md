---
title: Prototyping the message list
---

You'll start by prototyping your app's first feature: a list of messages for users to see. Since you'll be prototyping, go ahead and boot your project into prototype mode. Run this command from your project folder in the command line:

```
pakyow prototype
```

Prototype mode lets you see a navigable, frontend-only version of your project right in your web browser. It's the best place to start designing and building the interface for a new feature. You can boot back into prototype mode at any point in your project's development, giving you a consistent place to do all of your design work from.

Okay, let's create our first frontend view template. Each view template defines part of the interface for your project using plain html. Pakyow composes your templates together into what the user sees and interacts with in their web browser. Our first view template will present a list of messages for the user.

Define the following template in the `frontend/pages` folder:

<div class="filename">
  frontend/pages/index.html
</div>

```html
<article binding="message">
  <p binding="content">
    Message content goes here.
  </p>
</article>
```

Make sure the file is saved, then visit <a href="http://localhost:3000/" target="_blank">localhost:3000</a> in your favorite web browser. You'll see the root index page displayed just as you defined it:

![Pakyow Example: Message List Prototype](https://github.com/metabahn/pakyow-marketing-public/raw/master/docs/common/images/hello-example-screen-1.png "Pakyow Example: Message List Prototype")

Looks like you're off and running! Note that your pages may look a bit different, since the screenshots in this guide are pulled from the example app. Feel free to copy those assets to your project 😃

Thinking ahead, it would be helpful to tell the first user of the app what to do when no messages have been created. You can define an empty message by adding a new version of the message element to the same `index.html` page as before:

<div class="filename">
  frontend/pages/index.html
</div>

```html
<article binding="message">
  <p binding="content">
    Message content goes here.
  </p>
</article>

<p binding="message" version="empty">
  No messages yet. Try creating one!
</p>
```

Reload your web browser and you'll see both versions:

![Pakyow Example: Message List Prototype with Empty Version](https://github.com/metabahn/pakyow-marketing-public/raw/master/docs/common/images/hello-example-screen-2.png "Pakyow Example: Message List Prototype with Empty Version")

In just a minute we'll see how Pakyow handles these two versions of our message elements. But first, we need a way for our users to create new messages. You can do this by defining a form at the top of your `index.html` page:

<div class="filename">
  frontend/pages/index.html
</div>

```html
<form binding="message">
  <div class="form-field">
    <input type="text" placeholder="Type your message..." binding="content">
  </div>

  <input type="submit" value="Create">
</form>

<article binding="message">
  <p binding="content">
    Message content goes here.
  </p>
</article>

<p binding="message" version="empty">
  No messages yet. Try creating one!
</p>
```

Reload your web browser once again and you'll see the form at the top of the screen:

![Pakyow Example: Message List Prototype with Form](https://github.com/metabahn/pakyow-marketing-public/raw/master/docs/common/images/hello-example-screen-3.png "Pakyow Example: Message List Prototype with Form")

Nice, you've prototyped your first feature! We could add more to the prototype, such as improving how it looks with stylesheets. For now let's move on and see how Pakyow turns our html view templates into a usable app.
