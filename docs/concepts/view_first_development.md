---
name: View-First Development
desc: Learn about view-first development.
---

Pakyow promotes a **view-first development process**. Put simply, view-first
development enables the presentation layer of a website or web app to be built
and maintained separately from the logic that renders it.

View-first development also informs how a project is built. In Pakyow,
development usually begins with the view, because this is that part that the
user sees. Immediately after generating a project, the presentation layer can be built and
viewed in a browser without requiring any backend code.

In Pakyow, the presentation layer consists of templates, pages, and partials --
all written in HTML (or your favorite template language). These different parts
are composable, allowing for reusability without writing any backend code.

- [Read more about Pakyow's presentation layer](/docs/presentation)

No changes to the presentation layer are required when adding backend code.
View logic is written outside of the view templates and uses a technique called
data binding to insert values into the view.

- [Read more about Pakyow's view logic](/docs/view-logic)

This view-first process is the trick that makes Pakyow's auto-updating views
work without moving code to the client. It also makes development faster by
isolating concerns and promoting the reuse of rendering logic.
