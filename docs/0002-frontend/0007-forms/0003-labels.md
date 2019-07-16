---
title: Connecting labels to fields
---

Labels are an important way to improve the accessibility of your forms. Connecting a label to its field can be a challenge, especially for dynamic forms. Fortunately, Pakyow takes care of connecting labels to your forms fields for you. All you need to do is point the `for` attribute of the label to the `binding` of the form field.

Here's an example:

```html
<form binding="message">
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

Pakyow matches everything up, resulting in a rendered view that looks like this:

```html
<form action="/messages" method="post">
  <div class="form-input">
    <label for="e2n5">Title:</label>
    <input type="text" name="message[title]" id="e2n5">
  </div>

  <div class="form-input">
    <label for="9szk">Content:</label>
    <textarea name="message[content]" id="9szk"></textarea>
  </div>

  <input type="submit" value="Save Message">
</form>
```

The field ids are randomly generated and added to the field's related label. That's all there is to it!
