---
name: View-First Development
desc: Learn about view-first development.
---

Pakyow promotes a **view-first development process**. What's that, you say? To
put it simply, view-first development is a process that enables the presentation
layer of a website or web app to be built completely separate from the backend
code.

Immediately after generating a project, the presentation layer can be built and
viewed in a browser without requiring any backend code. The presentation layer
consists of templates, pages, and partials -- all written in HTML (or your
favorite template language). These different parts are composable, allowing for
reusability without writing any backend code.

- [Read more about Pakyow's presentation layer](/docs/presentation)

Once a backend is added, views can be rendered without any changes to the
presentation layer. View logic is written outside of the presentation layer and
instead acts upon the views. This is enabled with a process called data binding.

- [Read more about Pakyow's view logic](/docs/view-logic)

This view-first process provides the base functionality for Pakyow's
auto-updating views. It also makes development smoother by isolating
concerns and promoting the reuse of rendering logic.
