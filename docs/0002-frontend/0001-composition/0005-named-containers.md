---
title: Using multiple named containers
---

Layouts can define any number of containers, each with a unique name. Here's a layout that defines a `footer` container to go along with the standard `default` container:

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
</head>

<body>
  <!-- @container -->

  <footer>
    <!-- @container footer -->
  </footer>
</body>
</html>
```

Defining content for a named container happens with the `@within` directive in a page:

<div class="filename">
  frontend/pages/index.html
</div>

```html
<h1>
  Hello Web
</h1>

<!-- @within footer -->
  Custom Footer Content
<!-- /within -->
```

The composed view looks like this:

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

  <footer>
    Custom Footer Content
  </footer>
</body>
</html>
```
