---
name: Binding Nested Scopes
desc: Binding data to a nested scope.
---

It's often necessary to have nested scopes in a view. For example, if we're presenting comments for a post we might have the following:

```html
<div data-scope="post">
  <h1 data-prop="title">
    Title Goes Here
  </h1>

  <p data-prop="body">
    Body goes here.
  </p>

  <ul>
    <li data-scope="comment" data-prop="body">
      Comment body goes here.
    </li>
  </ul>
</div>
```

Pakyow's Binding API makes binding data to this view relatively easy:

```ruby
data = {
  title: 'First Post',
  body:  'This is the first post',

  comments: [
    { body: 'First comment' },
    { body: 'Second comment' },
    { body: 'Third comment' },
  ]
}

view.scope(:post).apply(data) do |ctx, post_data|
  ctx.scope(:comment).apply(post_data[:comments])
end
```

Here's the result:

```html
<div data-scope="post">
  <h1 data-prop="title">
    First Post
  </h1>

  <p data-prop="body">
    This is the first post
  </p>

  <ul>
    <li data-scope="comment" data-prop="body">
      First comment
    </li>

    <li data-scope="comment" data-prop="body">
      Second comment
    </li>

    <li data-scope="comment" data-prop="body">
      Third comment
    </li>
  </ul>
</div>
```
