---
title: Building dynamic titles
---

Page titles can also contain dynamic values. For example, in a blog the title for the "show post" page should include the title of the current post. But since the post is pulled from the database when the view is rendered, these values can't be hardcoded.

Fortunately there's a way to handle these more complex cases:

```html
---
title: {post.title} - My App
---

...
```

Assuming the backend exposes an object for `post`, the value for the exposed object's `title` attribute will be used. Here's an example:

```ruby
expose :post, {
  title: "Hello Web"
}
```

The rendered page title would be "Hello Web - My App".
