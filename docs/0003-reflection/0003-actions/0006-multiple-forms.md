---
title: Multiple forms for a single action
---

As your project grows, you may have several forms that submit to the same endpoint. Each form might be defined with its own rules for validation, or even completely different fields. Reflection is smart enough to distinguish between form submissions and perform the correct behavior for each.

Here are two forms that will both be hooked up to the `messages_create` action:

```ruby
<form binding="message">
  <div class="form-field">
    <input type="text" binding="title">
  </div>

  <div class="form-field">
    <input type="text" binding="content" required>
  </div>

  <input type="submit" value="Create" class="button">
</form>

<form binding="message">
  <div class="form-field">
    <input type="text" binding="content" required>
  </div>

  <input type="submit" value="Create" class="button">
</form>
```

These forms are pretty similar, the one difference being that the first form defines an optional field for `title`. When the first form is submitted, the action will allow a value for `title` through during verification. But for the second form, the action will only expect a value for `content`.
