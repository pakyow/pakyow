---
title: Handling form errors
---

Pakyow provides a `form-errors` component that attaches error handling behavior to your forms. If the submitting values don't pass the verification and validation process on the backend, the form will automatically be re-rendered with error messages for the user.

You can attach the `form-errors` component to an element in your form using the `ui` attribute like this:

```html
<form binding="message">
  <ul class="form-errors" ui="form-errors">
    <li binding="error.message">
      Error message goes here.
    </li>
  </ul>

  <div class="form-input">
    <label for="title">Title:</label>
    <input type="text" binding="title">
  </div>

  <div class="form-input">
    <label for="content">Content:</label>
    <textarea binding="content"></textarea>
  </div>

  <input type="submit" value="Save Message">
</form>
```

Your form errors element should include a binding within it that defines the `error` binding type along with a `message` binding attribute. This is where specific error messages will be presented for the user.

For example, let's assume that both fields in the above form are required. If the user submits the form form without providing values, the form would be re-rendered with errors like this:

```html
<form action="/messages" method="post">
  <ul class="form-errors">
    <li>
      Title cannot be blank
    </li>

    <li>
      Content cannot be blank
    </li>
  </ul>

  <div class="form-input">
    <input type="text" name="message[title]">
  </div>

  <div class="form-input">
    <textarea name="message[content]"></textarea>
  </div>

  <input type="submit" value="Save Message">
</form>
```

In some cases you may not want to present specific errors. A good example is a sign in form, where you want to tell the user that their sign in failed but don't want to tell them exactly why. You can handle errors like this by defining the `form-errors` component within an `error` binding:

```html
<form binding="message">
  <div class="form-errors" ui="form-errors">
    The values you provided were invalid.
  </div>

  ...
</form>
```

When Pakyow re-renders the errored form, it will only show the component and not try to populate it with specific error messages.

### Styling form errors

Pakyow leaves it to you to style form errors to match the look and feel of your application. However, it does add the `ui-hidden` helper class to the `form-errors` element when the form is in a non-errored state:

```html
<form binding="message">
  <div class="form-errors ui-hidden" ui="form-errors">
    The values you provided were invalid.
  </div>

  ...
</form>
```

It's recommended that you define styles for this helper class to hide elements with the `ui-hidden` class:

```css
.ui-hidden {
  display: none;
}
```

### Styling errored fields

When Pakyow renders a form with errors, it renders each invalid field in an errored state as well. Each field that has an error will receive a `ui-errored` class. You can define your own styles to indicate errored fields to your users.

Pakyow also adds the error message for the field to the field's `title` attribute. This is useful if you want to present tooltips or other callouts to each field rather than present errors at the top of the form.

Here's what an errored field looks like:

```html
<div class="form-input">
  <input type="text" name="message[title]" class="ui-errored" title="Title cannot be blank">
</div>
```

### Styling errored forms

Just like errored fields, errored forms will receive the `ui-errored` class.

```html
<form action="/messages" method="post" class="ui-errored">
  ...
</form>
```
