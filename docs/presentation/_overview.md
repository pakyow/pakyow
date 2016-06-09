---
name: Presentation
desc: Building the presentation layer in Pakyow.
---

An app's views are grouped into a view store, which is a hierarchical set of
view components. These components are composed together into the full view for a
particular request. The view components describe how they are to be composed
together, meaning views can be created *without writing anything but HTML*.

There are three parts to a view: templates, pages, and partials (covered in
detail below). First, let's discuss how view composition takes place.

## View Composition

When a request is received, `Pakyow::Presenter` finds a matching path in any
registered view stores (`app/views` by default). Here's an example view store
that defines three separate pages:

```
app/views/
  _templates/
    default.html

  index.html

  nested/
    deep.html
    index.html
```

A request to `/` would result in Presenter using the `/index.html` page as the
starting point for composition. Similarly, a request to `/nested` would result
in `/nested/index.html` being used as the starting point. If `/nested/deep` was
requested, `/nested/deep.html` would be used since there was no page defined at
the `/nested/deep/index.html` path. If no page is found, Presenter will raise a
404 error. *Pages are a required part of view composition.*

Once Presenter finds the page to use, it will identify the template needed to
compose the page into. The default template is always `_templates/default.html`.
A page can also override the template (this is discussed in more detail below).

Presenter looks for containers that the template defines, then finds matching
content defined in the page. Each bit of content is composed into the template
containers. Let's look at an example.

Here's a template:

```html
<html>
<body>
  <!-- @container -->

  <footer>
    <!-- @container footer -->
  </footer>
</body>
</html>
```

Here's the page:

```html
content goes here

<!-- @within footer -->
  footer content goes here
<!-- /within -->
```

And here's the fully composed view:

```html
<html>
<body>
  content goes here

  <footer>
    footer content goes here
  </footer>
</body>
</html>
```

Now, how do partials fit into this? This is best explained with an example.
Here's our view store, complete with partials (the files with leading `_`):

```
app/views/
  _reusable.html
  index.html

  nested/
    _reusable.html
```

Here's the `/index` page:

```html
content goes here

<!-- @include reusable -->
```

Here's the `/_reusable` partial:

```html
reusable
```

Here's the `/nested/_reusable` partial:

```html
nested reusable
```

When composed at `/`, Presenter will use the `/_reusable` partial, resulting in
this composed view (intentionally leaving the template out of this):

```html
content goes here

reusable
```

And here's the composed view at `/nested`:

```html
content goes here

nested reusable
```

Because there is no `/nested/index` page, Presenter falls back to `/index`. But
it composes the `/nested/_reusable` partial since it is considered to be *more
specific*. This provides unprecedented flexibility in how you define your views.

## Templates

A template defines the common structure for the view. During composition,
content from a page will be composed into containers defined in the template.
Containers are defined with an inline comment:

```html
<!-- @container container_name -->
```

By default, all templates are defined in the `app/views/_templates` directory.
Every generated Pakyow project includes a `default.html` template.

## Pages

A page defines specific content that will be composed into the template. When
fulfilling a request, Presenter first identifies the page to use based on the
request path. For example, a request for `/` would map to the `/index` page.
Pages can also be nested under folders, meaning either `/foo.html` or
`/foo/index.html` could be used for a view at path `/foo`.

A page implements a template. If a template isn't specified, Pakyow uses the
default template (named `default.html`). A template can be specified by adding
YAML front-matter to the page:

```html
---
template: some_template
---

page content goes here
```

The title for a page can also be specified in the front-matter:

```html
---
title: This is my page title
---
```

## Partials

A partial is a reusable view that can be included into a template, page, or
another partial. They are defined at some location in the view store hierarchy
with a leading underscore (`_`). Including them is easy:

```html
<!-- @include some_partial -->
```
