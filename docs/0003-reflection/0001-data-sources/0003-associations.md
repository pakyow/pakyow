---
title: Associations
---

Assocations describe how the data sources in your application are related. Pakyow discovers associations between data sources based on a few aspects of the frontend view template structure. All of the reflected association behavior is included below.

## Nested binding types

When Reflection encounters a binding type nested within another type, it assumes that the two types are related to each other. For example:

```html
<article binding="message">
  <article binding="reply">
    <p binding="body">
      reply body goes here
    </p>
  </article>
</article>
```

Because `reply` is nested in `message`, the reflected `messages` data source will contain a `has_many :replies` association. The reciprocal association is also defined for replies back to messages, meaning the `replies` data source will contain a `belongs_to :message` association.

Pakyow manages associations for you, but a basic understanding of how associations are represented in the database can be helpful. In practical terms, associations define columns in the database that tie data together. In the `has_many/belongs_to` case that we have here, the `replies` table will contain a foreign key named `message_id` that contains the id of the related message.

## Nested view paths

Pakyow defines assocations for sources that appear in nested view paths. For example:

<div class="filename">
  frontend/pages/posts/comments/new.html
</div>

```html
<form binding="comment">
  ...
</form>
```

The form isn't defined in the `post` binding type but will still belong to the `posts` source. This is because the comment binding type is located at a view path within the RESTful resource path for posts (`/posts`).

## Custom associations

You may need to change the default association behavior from time to time. A common case is needing a `has_one` association between sources instead of the default `has_many` association. Here's an example:

```html
<article binding="message">
  <div binding="user">
    <span binding="name">
      user name goes here
    </span>
  </div>
</article>
```

Pakyow assumes that `messages` have many `users`. But in this case the view template is attempting to present the author for a message. Since a message can only have one author, a `has_one` association would be more appropriate. This can be done by creating a backend data source and defining the association:

```ruby
source :messages do
  has_one :user
end
```

Reflection will still extend the data source with other associations, but will use the defined association for `users`.

* [Read more about customizing data sources &rarr;](doc:reflection/data-sources/customizing)
