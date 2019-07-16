---
title: UI Modes
---

Most UIs have multiple states they need to be rendered in. The header might present a "sign in" link for users who aren't currently signed in, but for signed in users might present a "sign out" link along with a link to their account settings. These kind of view states can be tricky to define, and even harder to communicate across the stack.

UI modes provides a way to solve these problems by defining presentation states right in the view templates. This gives the frontend designer control over the states available and how they change frontend behavior. Modes are then exposed to the backend, letting the backend developer make a decision about what state to render in based on the current app state.

Let's look at a real example. Here's a view template that defines two modes—one for signed in users and another for signed out users:

```html
<header mode="signed-out">
  <nav>
    <a href="/login">
      Sign In
    </a>
  </nav>
</header>

<header mode="signed-in">
  <nav>
    <a href="/settings">
      Account Settings
    </a>

    <a href="/logout">
      Sign Out
    </a>
  </nav>
</header>
```

Nodes that define a mode will be removed during rendering unless the mode is specified as a valid render mode. Dynamic render modes are specified in the backend code, but one or more default modes can be defined in the view template using front-matter:

```html
---
modes:
- signed-out
---

...
```

The `signed-out` mode will be rendered by default unless other render modes are specified on the backend. In our case, the backend developer would choose to render with the `signed-in` mode if the current user has a valid session.

UI Modes are also exposed when running in prototype mode, letting you render the view with any combination of modes to design the interface in any state. You'll learn more about this in the next guide on prototyping.
