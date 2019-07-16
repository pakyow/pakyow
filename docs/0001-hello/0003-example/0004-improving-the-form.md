---
title: Improving the form
---

Right now users can create messages without typing any content. This makes for a pretty poor user-experience, so let's add some validation and error handling to our form. First, attach additional behavior to your form by adding the `ui` attribute:

```html
<form binding="message" ui="form">
  ...
</form>

...
```

Pakyow ships with a form view component that handles things like submitting in the background and handling errors that occur.

Next, make the message content required by adding the `required` attribute to the text field:

```html
<form binding="message" ui="form">
  <div class="form-field">
    <input type="text" placeholder="Type your message..." binding="content" required>
  </div>

  ...
</form>

...
```

Finally, add an unordered list for presenting errors in your form:

```html
<form binding="message" ui="form">
  <ul class="form-errors" ui="form-errors">
    <li binding="error.message">
      Error message goes here.
    </li>
  </ul>

  ...
</form>

...
```

Reload your web browser and you'll find that it's no longer possible to create a message without first writing some content. What you're seeing here is the built-in browser validation, but Pakyow has also attached validation to your app. To see it, simply add the `novalidate` attribute to the form:

```html
<form binding="message" ui="form" novalidate>
  ...
</form>

...
```

This tells the web browser to skip validation and let the application take care of it instead. Reload your web browser and use the form to create a message without any content. Now you'll see errors presented in the list:

![Pakyow Example: Form Errors](https://github.com/metabahn/pakyow-marketing-public/raw/master/docs/common/images/hello-example-screen-7.png "Pakyow Example: Form Errors")

Let's continue improving our application by adding the ability to reply to messages. We'll do this in the next section.
