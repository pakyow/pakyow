---
title: Defining form fields
---

Form fields are added to a form to provide specific values for the form's data type. Here we define two fields along with a button that submits the form when clicked. The first field submits the title of the message, while the second field submits the message content:

```html
<form binding="message">
  <div class="form-input">
    <input type="text" binding="title">
  </div>

  <div class="form-input">
    <textarea binding="content"></textarea>
  </div>

  <input type="submit" value="Save Message">
</form>
```

Pakyow automatically presents existing values in the form fields just like it does for other bindings.

## How Pakyow names form fields

You may notice that the above example doesn't explicitly set the `name` attribute on the form fields. Pakyow hooks this up for you so that the backend receives data in a consistent manner. Here's how the fields will be named:

```html
<form action="/messages" method="post">
  <div class="form-input">
    <input type="text" name="message[title]">
  </div>

  <div class="form-input">
    <textarea name="message[content]"></textarea>
  </div>

  <input type="submit" value="Save Message">
</form>
```

The backend can access submitted values through the `params[:message]` helper.

In some cases you may want to control how the field is named. You can do this by naming a form input yourself:

```html
<div class="form-input">
  <input type="text" name="my_title" binding="title">
</div>
```

Pakyow will submit the value as `my_title`, but will still present the existing `title` value in the form field.
