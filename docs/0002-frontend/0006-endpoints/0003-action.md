---
title: Specifying an endpoint action
---

In more complicated navigation interfaces, the navigation item may be different than the element that causes the navigation action to occur. Here's an example view template that defines a separate endpoint action:

```html
<nav>
  <ol>
    <li binding="guide" endpoint="guides_show">
      <a href="/guides/show" binding="title" endpoint-action>
        Guide Title
      </a>
    </li>
  </ol>
</nav>
```

Adding the `endpoint-action` attribute to the `a` element separates the endpoint node from the action node. This causes the `li` endpoint node to receive the `ui-current` and `ui-active` classes, with the `a` endpoint action node receiving the `href` value.
