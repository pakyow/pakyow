---
title: Reusing content with partials
---

Partials are the third type of view template designed to break your frontend templates into even smaller, more reusable pieces. Using partials, you can move the common parts of a view template into its own file and then include it whenever you need it.

Partials are placed alongside pages in the `frontend/pages` folder, but are prefixed with an underscore. Here's an example view structure that contains a layout, page, and a partial named `_messages.html`:

```
frontend/
  layouts/
    default.html
  pages/
    _messages.html
    index.html
```

Here's the content of the `_messages.html` partial:

<div class="filename">
  frontend/pages/_messages.html
</div>

```html
<article>
  <h1>this is a message</h1>
</article>
```

Partials are included into other view templates using the `@include` directive. For example, the `index.html` page can include the partial like this:

```html
<h1>
  Here are your messages:
</h1>

<!-- @include messages -->
```

The composed view would look like this:

```html
<h1>
  Here are your messages:
</h1>

<article>
  <h1>this is a message</h1>
</article>
```

Partials can be included into any view template—pages, layouts, or even other partials. This simple feature gives you a lot of power to build a flexible frontend while reducing duplication.

## Defining partials for nested presentation paths

Partials can be defined at any presentation path, including nested paths. More specific presentation paths will inherit partials from parent paths and can override specific partials as necessary.

The `_messages.html` partial from above can be redefined at the `show` path, making it available to any view template within the `show` path. Let's build up a complete example, starting with one top-level partial:

```
frontend/
  layouts/
    default.html
  pages/
    _messages.html
    show/
      index.html
```

The `show` path inherits the `messages` partial and can include it:

<div class="filename">
  frontend/pages/show/index.html
</div>

```html
<!-- @include messages -->
```

The `show` path can override the inherited partial by defining a view template at `show/_messages.html`. This more specific partial will be used when included by templates within the `frontend/pages/show` presentation path, while other presentation paths will include the `frontend/pages/_messages.html` partial.


## Defining global partials

Partials can also be defined globally, making them includable into any view template, including layouts. Global partials are defined by creating a view template in the `frontend/includes` folder:

```
frontend/
  includes/
    messages.html
  layouts/
    default.html
  pages/
    index.html
```

Unlike other partials, filenames for global includes are not prefixed with an underscore. But otherwise they behave just like other partials and can be included with the same `@include` directive:

```html
<!-- @include messages -->
```
