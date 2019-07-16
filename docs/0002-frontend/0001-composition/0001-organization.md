---
title: Organizing view templates
---

Pakyow builds the content, or view, for a request based on the request path. Frontend view templates, along with assets, are defined in a structure mirroring the request paths that your application will serve content for. These paths are called presentation paths.

For example, a simple chat app might have two presentation paths:

1. Index, which presents a list of messages.

2.  Show, which presents a single message and its details.

Here's how the view templates for this application would be organized:

```
frontend/
  layouts/
    default.html
  pages/
    index.html
    messages/
      show.html
```

There are three types of view templates: pages, layouts, and partials.

Pages, located in the `frontend/pages` folder, define content for a specific page in your application. When the application receives a request, the page matching the request path is chosen for composition.

For example, a request to `http://your-app.com/` will match the index page located at `frontend/pages/index.html`. When a matching page is found, it's composed with a layout to form a complete view.

Layouts, located in the `frontend/layouts` folder, define the common elements that are used across several pages—such as a header, footer, or sidebar. The `default.html` layout is used by default, or pages can define a specific layout to use (this is discussed more below).

Each layout defines one or more containers, each one defining where content from a page should be mixed in. Below is the `default.html` layout that you'll find in a generated project:

<div class="filename">
  frontend/layouts/default.html
</div>

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
</head>

<body>
  <!-- @container -->
</body>
</html>
```

This layout defines a single, unnamed container. During composition, the `<!— @container —>` comment, or directive is replaced with content from the matching page. Let's step through a complete example to be more clear about how.

Pakyow receives a request at `http://your-site.com/` and chooses the `frontend/pages/index.html` page based on the presentation path. Here's the page content:

<div class="filename">
  frontend/pages/index.html
</div>

```html
<h1>
  Hello Web
</h1>
```

The fully composed view would look like this:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
</head>

<body>
  <h1>
    Hello Web
  </h1>
</body>
</html>
```

The  `<!— @container —>`  directive in the layout was replaced with the page content just as we expected. Pakyow sends the fully composed view in the response, which is presented in the user's web browser.
